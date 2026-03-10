import SwiftUI
import AppKit

struct MediaView: View {
    @State private var manager = MediaManager()

    var body: some View {
        HStack(spacing: 16) {
            // Artwork
            artworkView

            // Info + controls
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(manager.title ?? "Nothing Playing")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let artist = manager.artist {
                        Text(artist)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: 0xa8dadc))
                            .lineLimit(1)
                    }
                    if let album = manager.album {
                        Text(album)
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: 0xa8dadc).opacity(0.6))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Playback controls
                HStack(spacing: 20) {
                    MediaControlButton(icon: "backward.fill") {
                        manager.sendCommand(.previousTrack)
                    }
                    MediaControlButton(
                        icon: manager.isPlaying ? "pause.fill" : "play.fill",
                        size: 20
                    ) {
                        manager.sendCommand(.togglePlayPause)
                    }
                    MediaControlButton(icon: "forward.fill") {
                        manager.sendCommand(.nextTrack)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear { manager.startObserving() }
        .onDisappear { manager.stopObserving() }
    }

    @ViewBuilder
    private var artworkView: some View {
        if let artwork = manager.artwork {
            Image(nsImage: artwork)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: 0x16213e))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: 0xa8dadc).opacity(0.4))
                )
        }
    }
}

// MARK: - Control Button

private struct MediaControlButton: View {
    let icon: String
    var size: CGFloat = 16
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(Color(hex: 0xe94560))
                .frame(width: 36, height: 36)
                .background(Color(hex: 0x16213e))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
