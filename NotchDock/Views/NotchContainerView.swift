import SwiftUI

/// Shared expand/collapse state driven by NotchWindowController.
@Observable
final class NotchState {
    var isExpanded: Bool = false
}

struct NotchContainerView: View {
    var state: NotchState

    // Single MediaManager instance shared down to MediaView and the collapsed pill
    @State private var media = MediaManager()

    var body: some View {
        ZStack(alignment: .top) {

            // ── Expanded panel ───────────────────────────────────────────
            // Always in the hierarchy; the clip shape handles visibility.
            ExpandedView()
                .opacity(state.isExpanded ? 1 : 0)
                .allowsHitTesting(state.isExpanded)

            // ── Collapsed pill album-art indicator ───────────────────────
            // Shows the current track artwork as a tiny thumbnail inside
            // the pill when something is playing and the panel is collapsed.
            if let artwork = media.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    // Centre vertically in the 32 pt pill; top 7 pt are behind
                    // the bezel, so visible centre ≈ padding 13 pt from window top.
                    .padding(.top, 13)
                    .opacity(state.isExpanded ? 0 : 1)
            }
        }
        // Black background — the clip shape cuts it to the correct pill/panel outline
        .background(Color.black)
        .clipShape(NotchExpansionShape(progress: state.isExpanded ? 1 : 0))
        // Spring drives both the clip-shape morph AND the opacity fade simultaneously
        .animation(.spring(duration: 0.45, bounce: 0.25), value: state.isExpanded)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(media)
        .onAppear  { media.startObserving() }
        .onDisappear { media.stopObserving() }
    }
}
