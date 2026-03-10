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
        ZStack(alignment: .top) {
            // Top corners use a small radius (~10 pt) to match the MacBook screen
            // bezel curvature. The top 7 pt are pushed off-screen so they blend
            // seamlessly into the physical bezel.
            UnevenRoundedRectangle(
                topLeadingRadius: 10,
                bottomLeadingRadius: 22,
                bottomTrailingRadius: 22,
                topTrailingRadius: 10,
                style: .continuous
            )
            .fill(Color.black)

            VStack(spacing: 0) {
                // ── Wing tab bar ──────────────────────────────────────────
                // Sits in the visible portion of the notch "wings" (the areas
                // to the left and right of the physical notch camera bump).
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
                // 7 pt overflow is off-screen; add 5 pt more so tabs sit
                // visually just below the bezel edge.
                .padding(.top, 12)
                .frame(height: 38)

                // ── Content ──────────────────────────────────────────────
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
