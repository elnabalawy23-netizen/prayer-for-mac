import AppKit

extension NSScreen {
    /// The built-in display with a camera notch, if any.
    static var builtInWithNotch: NSScreen? { screens.first { $0.notchSize != nil } }

    /// Physical notch size in points, derived from the menu-bar areas left and right of it.
    var notchSize: CGSize? {
        guard safeAreaInsets.top > 0,
              let left = auxiliaryTopLeftArea,
              let right = auxiliaryTopRightArea else { return nil }
        return CGSize(width: frame.width - left.width - right.width, height: safeAreaInsets.top)
    }
}
