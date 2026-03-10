import SwiftUI

struct CollapsedView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.black)
            .frame(
                width: CGFloat(NotchWindowController.collapsedWidth),
                height: CGFloat(NotchWindowController.collapsedHeight)
            )
            // Subtle breathing indicator — a small teal dot when something is playing
            .overlay(alignment: .center) {
                Circle()
                    .fill(Color(hex: 0xa8dadc))
                    .frame(width: 6, height: 6)
                    .opacity(0.5)
            }
    }
}
