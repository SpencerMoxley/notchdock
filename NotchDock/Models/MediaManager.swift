import Foundation
import AppKit

// MARK: - MediaRemote private framework bindings

private typealias MRMediaRemoteGetNowPlayingInfoFn = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
private typealias MRMediaRemoteGetNowPlayingApplicationIsPlayingFn = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
private typealias MRMediaRemoteSendCommandFn = @convention(c) (UInt32, AnyObject?) -> Bool
private typealias MRMediaRemoteRegisterForNowPlayingNotificationsFn = @convention(c) (DispatchQueue) -> Void

private let kMRPlay:          UInt32 = 0
private let kMRPause:         UInt32 = 1
private let kMRTogglePlayPause: UInt32 = 2
private let kMRNextTrack:     UInt32 = 4
private let kMRPreviousTrack: UInt32 = 5

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
    var title:    String?
    var artist:   String?
    var album:    String?
    var artwork:  NSImage?
    var isPlaying: Bool = false

    private var handle: UnsafeMutableRawPointer?
    private var nowPlayingInfoObserver: NSObjectProtocol?

    // Lazily resolved function pointers
    private var fnGetInfo:      MRMediaRemoteGetNowPlayingInfoFn?
    private var fnIsPlaying:    MRMediaRemoteGetNowPlayingApplicationIsPlayingFn?
    private var fnSendCommand:  MRMediaRemoteSendCommandFn?
    private var fnRegister:     MRMediaRemoteRegisterForNowPlayingNotificationsFn?

    // MARK: - Lifecycle

    func startObserving() {
        loadFramework()
        fnRegister?(DispatchQueue.main)
        refresh()

        let center = NotificationCenter.default
        // kMRMediaRemoteNowPlayingInfoDidChangeNotification
        let name = Notification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification")
        nowPlayingInfoObserver = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            self?.refresh()
        }
    }

    func stopObserving() {
        if let obs = nowPlayingInfoObserver {
            NotificationCenter.default.removeObserver(obs)
        }
        if let handle { dlclose(handle) }
        self.handle = nil
    }

    func sendCommand(_ command: MediaCommand) {
        _ = fnSendCommand?(command.rawValue, nil)
    }

    // MARK: - Private

    private func loadFramework() {
        guard handle == nil else { return }
        let path = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
        handle = dlopen(path, RTLD_LAZY)
        guard let h = handle else { return }

        fnGetInfo = unsafeBitCast(dlsym(h, "MRMediaRemoteGetNowPlayingInfo"), to: MRMediaRemoteGetNowPlayingInfoFn?.self)
        fnIsPlaying = unsafeBitCast(dlsym(h, "MRMediaRemoteGetNowPlayingApplicationIsPlaying"), to: MRMediaRemoteGetNowPlayingApplicationIsPlayingFn?.self)
        fnSendCommand = unsafeBitCast(dlsym(h, "MRMediaRemoteSendCommand"), to: MRMediaRemoteSendCommandFn?.self)
        fnRegister = unsafeBitCast(dlsym(h, "MRMediaRemoteRegisterForNowPlayingNotifications"), to: MRMediaRemoteRegisterForNowPlayingNotificationsFn?.self)
    }

    private func refresh() {
        fnGetInfo?(DispatchQueue.main) { [weak self] info in
            self?.updateNowPlaying(from: info)
        }
        fnIsPlaying?(DispatchQueue.main) { [weak self] playing in
            self?.isPlaying = playing
        }
    }

    private func updateNowPlaying(from info: [String: Any]) {
        // Key names from MediaRemote reverse engineering
        title  = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String
        artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String
        album  = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String

        if let artworkData = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
            artwork = NSImage(data: artworkData)
        } else {
            artwork = nil
        }
    }
}
