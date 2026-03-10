import SwiftUI

enum NotchTab: String, CaseIterable {
    case widgets = "Music"
    case storage = "Tray"

    var icon: String {
        switch self {
        case .widgets: return "music.note"
        case .storage: return "tray.and.arrow.down"
        }
    }
}

struct ExpandedView: View {
    @State private var selectedTab: NotchTab = .widgets

    var body: some View {
        VStack(spacing: 0) {

            // ── Tab bar (lives in the notch wing area) ───────────────────
            HStack {
                HStack(spacing: 4) {
                    ForEach(NotchTab.allCases, id: \.self) { tab in
                        TabPill(
                            title: tab.rawValue,
                            icon:  tab.icon,
                            isSelected: selectedTab == tab
                        ) { selectedTab = tab }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            // Window is pushed 7 pt off-screen at top; add 12 pt more so
            // pills sit comfortably below the visible bezel edge.
            .padding(.top, 12)
            .frame(height: 38)

            // ── Content ──────────────────────────────────────────────────
            Group {
                switch selectedTab {
                case .widgets:
                    HStack(alignment: .top, spacing: 0) {
                        MediaView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.leading, 14)
                            .padding(.trailing, 8)

                        Rectangle()
                            .fill(Color.white.opacity(0.07))
                            .frame(width: 1)
                            .padding(.vertical, 4)

                        NotesView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.leading, 8)
                            .padding(.trailing, 14)
                    }

                case .storage:
                    FileTrayView()
                        .padding(.horizontal, 14)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tab Pill

private struct TabPill: View {
    let title: String
    let icon:  String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.38))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.14) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
