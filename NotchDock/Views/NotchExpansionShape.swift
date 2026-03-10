import SwiftUI

/// A Shape that morphs between a centered pill (collapsed) and the full panel
/// (expanded) as `progress` goes from 0 → 1.  Because it conforms to
/// `Animatable`, SwiftUI will interpolate `progress` frame-by-frame through
/// whatever animation is applied to the parent, producing a smooth morph.
struct NotchExpansionShape: Shape, Animatable {

    /// 0 = collapsed pill  |  1 = fully expanded panel
    var progress: CGFloat

    private let pillW: CGFloat = 162
    private let pillH: CGFloat = 32

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let w = lerp(pillW,  rect.width,  progress)
        let h = lerp(pillH,  rect.height, progress)

        // Keep the shape horizontally centred at all sizes
        let x = (rect.width - w) / 2
        let y: CGFloat = 0

        // Top corners shrink from pill-radius → bezel-matching radius
        // Bottom corners grow from pill-radius → full rounded-rect radius
        let topR    = lerp(pillH / 2, 12, progress)   // 16 → 12
        let bottomR = lerp(pillH / 2, 22, progress)   // 16 → 22

        return Path { p in
            p.move(to: CGPoint(x: x + topR, y: y))
            p.addLine(to: CGPoint(x: x + w - topR, y: y))
            p.addArc(
                center: CGPoint(x: x + w - topR, y: y + topR),
                radius: topR,
                startAngle: .degrees(-90), endAngle: .degrees(0),
                clockwise: false
            )
            p.addLine(to: CGPoint(x: x + w, y: y + h - bottomR))
            p.addArc(
                center: CGPoint(x: x + w - bottomR, y: y + h - bottomR),
                radius: bottomR,
                startAngle: .degrees(0), endAngle: .degrees(90),
                clockwise: false
            )
            p.addLine(to: CGPoint(x: x + bottomR, y: y + h))
            p.addArc(
                center: CGPoint(x: x + bottomR, y: y + h - bottomR),
                radius: bottomR,
                startAngle: .degrees(90), endAngle: .degrees(180),
                clockwise: false
            )
            p.addLine(to: CGPoint(x: x, y: y + topR))
            p.addArc(
                center: CGPoint(x: x + topR, y: y + topR),
                radius: topR,
                startAngle: .degrees(180), endAngle: .degrees(270),
                clockwise: false
            )
            p.closeSubpath()
        }
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}
