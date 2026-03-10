import Foundation
import AppKit

// MARK: - MediaRemote private framework bindings

private typealias MRMediaRemoteGetNowPlayingInfoFn = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
private typealias MRMediaRemoteGetNowPlayingApplicationIsPlayingFn = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
private typealias MRMediaRemoteSendCommandFn = @convention(c) (UInt32, AnyObject?) -> Bool
private typealias MRMediaRemoteRegisterForNowPlayingNotificationsFn = @convention(c) (DispatchQueue) -> Void

private let kMRPlay:            UInt32 = 0
private let kMRPause:           UInt32 = 1
private let kMRTogglePlayPause: UInt32 = 2
private let kMRNextTrack:       UInt32 = 4
private let kMRPreviousTrack:   UInt32 = 5

enum MediaCommand {
    case play, pause, togglePlayPause, nextTrack, previousTrack

    var rawValue: UInt32 {
        switch self {
        case .play:            return kMRPlay
        case .pause:           return kMRPause
        case .togglePlayPause: return kMRTogglePlayPause
        case .nextTrack:       return kMRNextTrack
        case .previousTrack:   return kMRPreviousTrack
        }
    }
}

// MARK: - MediaManager

@Observable
final class MediaManager {
    var title:     String?
    var artist:    String?
    var album:     String?
    var artwork:   NSImage?
    var isPlaying: Bool = false

    private var handle: UnsafeMutableRawPointer?
    private var nowPlayingInfoObserver: NSObjectProtocol?
    private var isPlayingObserver:      NSObjectProtocol?
    private var pollTimer:              Timer?

    private var fnGetInfo:    MRMediaRemoteGetNowPlayingInfoFn?
    private var fnIsPlaying:  MRMediaRemoteGetNowPlayingApplicationIsPlayingFn?
    private var fnSendCommand: MRMediaRemoteSendCommandFn?
    private var fnRegister:   MRMediaRemoteRegisterForNowPlayingNotificationsFn?

    // MARK: - Lifecycle

    func startObserving() {
        loadFramework()
        fnRegister?(DispatchQueue.main)

        // First fetch — may return empty if MediaRemote hasn't warmed up yet.
        refresh()

        // Cascading retries — MediaRemote finishes its internal setup asynchronously;
        // later retries catch state that wasn't available immediately after registration.
        for delay in [0.5, 1.5, 4.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.refresh()
            }
        }

        // Permanent 5s poll — keeps state in sync when notifications don't fire
        // (common on macOS 14/15 when the playing app doesn't change).
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refresh()
        }

        let center = NotificationCenter.default

        // Fires when track info changes (new track, metadata update, etc.)
        let infoName = Notification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification")
        nowPlayingInfoObserver = center.addObserver(forName: infoName, object: nil, queue: .main) { [weak self] _ in
            self?.refresh()
        }

        // Fires when playback starts or stops
        let playingName = Notification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification")
        isPlayingObserver = center.addObserver(forName: playingName, object: nil, queue: .main) { [weak self] _ in
            self?.refresh()
        }
    }

    func stopObserving() {
        pollTimer?.invalidate()
        pollTimer = nil
        if let obs = nowPlayingInfoObserver { NotificationCenter.default.removeObserver(obs) }
        if let obs = isPlayingObserver      { NotificationCenter.default.removeObserver(obs) }
        nowPlayingInfoObserver = nil
        isPlayingObserver      = nil
        if let h = handle { dlclose(h) }
        handle = nil
    }

    func sendCommand(_ command: MediaCommand) {
        _ = fnSendCommand?(command.rawValue, nil)
        // Notification doesn't always fire for self-triggered changes; force a refresh.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.refresh()
        }
    }

    // MARK: - Private

    private func loadFramework() {
        guard handle == nil else { return }
        let path = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
        handle = dlopen(path, RTLD_LAZY)
        guard let h = handle else { return }

        fnGetInfo     = unsafeBitCast(dlsym(h, "MRMediaRemoteGetNowPlayingInfo"),                          to: MRMediaRemoteGetNowPlayingInfoFn?.self)
        fnIsPlaying   = unsafeBitCast(dlsym(h, "MRMediaRemoteGetNowPlayingApplicationIsPlaying"),          to: MRMediaRemoteGetNowPlayingApplicationIsPlayingFn?.self)
        fnSendCommand = unsafeBitCast(dlsym(h, "MRMediaRemoteSendCommand"),                               to: MRMediaRemoteSendCommandFn?.self)
        fnRegister    = unsafeBitCast(dlsym(h, "MRMediaRemoteRegisterForNowPlayingNotifications"),        to: MRMediaRemoteRegisterForNowPlayingNotificationsFn?.self)
    }

    private func refresh() {
        fnGetInfo?(DispatchQueue.main) { [weak self] info in
            self?.updateNowPlaying(from: info)
        }
    }

    private func updateNowPlaying(from info: [String: Any]) {
        title  = info["kMRMediaRemoteNowPlayingInfoTitle"]  as? String
        artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String
        album  = info["kMRMediaRemoteNowPlayingInfoAlbum"]  as? String

        if let data = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
            artwork = NSImage(data: data)
        } else {
            artwork = nil
        }

        // Derive isPlaying from PlaybackRate (more reliable on macOS 14/15 than the
        // separate MRMediaRemoteGetNowPlayingApplicationIsPlaying function).
        if let rate = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double {
            isPlaying = rate > 0
        } else {
            // PlaybackRate key absent — fall back to the dedicated function.
            fnIsPlaying?(DispatchQueue.main) { [weak self] playing in
                self?.isPlaying = playing
            }
        }
    }
}
