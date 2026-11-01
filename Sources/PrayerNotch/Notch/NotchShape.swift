import SwiftUI

/// The classic notch silhouette: flares outward at the top edge (so it reads as part of the
/// hardware notch) and rounds inward at the bottom.
struct NotchShape: InsettableShape {
    var topRadius: CGFloat
    var bottomRadius: CGFloat
    var inset: CGFloat = 0

    func inset(by amount: CGFloat) -> NotchShape {
        var copy = self
        copy.inset += amount
        return copy
    }

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topRadius, bottomRadius) }
        set { topRadius = newValue.first; bottomRadius = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        let rect = rect.insetBy(dx: inset, dy: inset)
        let t = topRadius
        let b = min(bottomRadius, (rect.height - t) / 1, (rect.width - 2 * t) / 2)
        let k: CGFloat = 0.5523 // circular-arc approximation
        var p = Path()

        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        // top-left flare
        p.addQuadCurve(to: CGPoint(x: rect.minX + t, y: rect.minY + t),
                       control: CGPoint(x: rect.minX + t, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + t, y: rect.maxY - b))
        // bottom-left corner
        p.addCurve(to: CGPoint(x: rect.minX + t + b, y: rect.maxY),
                   control1: CGPoint(x: rect.minX + t, y: rect.maxY - b + b * k),
                   control2: CGPoint(x: rect.minX + t + b - b * k, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - t - b, y: rect.maxY))
        // bottom-right corner
        p.addCurve(to: CGPoint(x: rect.maxX - t, y: rect.maxY - b),
                   control1: CGPoint(x: rect.maxX - t - b + b * k, y: rect.maxY),
                   control2: CGPoint(x: rect.maxX - t, y: rect.maxY - b + b * k))
        p.addLine(to: CGPoint(x: rect.maxX - t, y: rect.minY + t))
        // top-right flare
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.maxX - t, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
