import SwiftUI

enum NotchTab: String, CaseIterable {
    case media = "Media"
    case tray  = "Tray"
    case notes = "Notes"

    var icon: String {
        switch self {
        case .media: return "music.note"
        case .tray:  return "tray.and.arrow.down"
        case .notes: return "note.text"
        }
    }
}

struct ExpandedView: View {
    @State private var selectedTab: NotchTab = .media

    var body: some View {
        ZStack {
            // Background pill
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: 0x1a1a2e))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(hex: 0x0f3460), lineWidth: 1)
                )

            VStack(spacing: 0) {
                // Tab bar
                HStack(spacing: 0) {
                    ForEach(NotchTab.allCases, id: \.self) { tab in
                        TabButton(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            action: { selectedTab = tab }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)

                Divider()
                    .background(Color(hex: 0x0f3460))
                    .padding(.top, 8)

                // Content
                Group {
                    switch selectedTab {
                    case .media:
                        MediaView()
                    case .tray:
                        FileTrayView()
                    case .notes:
                        NotesPlaceholderView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(16)
            }
        }
        .frame(
            width: CGFloat(NotchWindowController.expandedWidth),
            height: CGFloat(NotchWindowController.expandedHeight)
        )
    }
}

// MARK: - Tab Button

private struct TabButton: View {
    let tab: NotchTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(tab.rawValue)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isSelected ? Color(hex: 0xe94560) : Color(hex: 0xa8dadc).opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? Color(hex: 0xe94560).opacity(0.12)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notes Placeholder

private struct NotesPlaceholderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "note.text")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: 0xa8dadc).opacity(0.4))
            Text("Notes coming soon")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: 0xa8dadc).opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
