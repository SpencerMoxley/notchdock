import SwiftUI
import AppKit

struct MediaView: View {
    // Shared instance injected by NotchContainerView
    @Environment(MediaManager.self) private var manager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                artworkView

                VStack(alignment: .leading, spacing: 2) {
                    Text(manager.title ?? "Nothing Playing")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let artist = manager.artist {
                        Text(artist)
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: 0xa8dadc))
                            .lineLimit(1)
                    }
                    if let album = manager.album {
                        Text(album)
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: 0xa8dadc).opacity(0.5))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 16) {
                Spacer()
                MediaControlButton(icon: "backward.fill") {
                    manager.sendCommand(.previousTrack)
                }
                MediaControlButton(icon: manager.isPlaying ? "pause.fill" : "play.fill", size: 18) {
                    manager.sendCommand(.togglePlayPause)
                }
                MediaControlButton(icon: "forward.fill") {
                    manager.sendCommand(.nextTrack)
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var artworkView: some View {
        if let artwork = manager.artwork {
            Image(nsImage: artwork)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: 0xa8dadc).opacity(0.35))
                )
        }
    }
}

// MARK: - Control Button

private struct MediaControlButton: View {
    let icon: String
    var size: CGFloat = 14
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.07))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
