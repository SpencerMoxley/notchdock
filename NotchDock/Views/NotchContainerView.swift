import SwiftUI

@Observable
final class NotchState {
    enum DisplayState { case collapsed, hovered, expanded }

    var display: DisplayState = .collapsed

    var isExpanded: Bool { display == .expanded }

    /// Progress fed into NotchExpansionShape.
    /// 0 = pill · 0.04 = hover nudge · 1 = full panel
    var expansionProgress: CGFloat {
        switch display {
        case .collapsed: return 0
        case .hovered:   return 0.04
        case .expanded:  return 1
        }
    }
}

struct NotchContainerView: View {
    var state: NotchState

    @State private var media = MediaManager()

    var body: some View {
        ZStack(alignment: .top) {

            // Expanded panel — always in hierarchy, clip handles visibility
            ExpandedView()
                .opacity(state.isExpanded ? 1 : 0)
                .allowsHitTesting(state.isExpanded)

            // Album-art thumbnail visible in pill when a track is playing
            if let artwork = media.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .padding(.top, 13)
                    .opacity(state.isExpanded ? 0 : 1)
            }
        }
        .background(Color.black)
        .clipShape(NotchExpansionShape(progress: state.expansionProgress))
        // Single spring drives all three state transitions.
        // Short duration keeps hover nudge snappy; bounce gives expand its pop.
        .animation(.spring(duration: 0.3, bounce: 0.18), value: state.display)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(media)
        .onAppear  { media.startObserving() }
        .onDisappear { media.stopObserving() }
    }
}
