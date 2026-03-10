import SwiftUI

/// Shared expand/collapse state driven by NotchWindowController.
@Observable
final class NotchState {
    var isExpanded: Bool = false
}

struct NotchContainerView: View {
    var state: NotchState

    var body: some View {
        ZStack {
            if state.isExpanded {
                ExpandedView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                    ))
            } else {
                CollapsedView()
                    .transition(.opacity)
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.18), value: state.isExpanded)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
