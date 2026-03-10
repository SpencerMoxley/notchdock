import SwiftUI

struct CollapsedView: View {
    var body: some View {
        // Pill sits at the very top-center of the fixed panel frame,
        // matching the physical notch. Transparent below.
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black)
                .frame(
                    width:  CGFloat(NotchWindowController.collapsedWidth),
                    height: CGFloat(NotchWindowController.collapsedHeight)
                )
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
