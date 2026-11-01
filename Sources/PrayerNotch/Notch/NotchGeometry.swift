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

    var displayID: CGDirectDisplayID {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }
}

/// Where the island lives: inside the hardware notch when the Mac has one, otherwise as a
/// virtual island hanging from the top edge of the main display, drawn with the same shape.
struct NotchLayout {
    let screen: NSScreen
    /// Physical notch size, or for a virtual island: no center gap and the strip height.
    let notchSize: CGSize
    let isVirtual: Bool

    /// Height of the virtual island's strip: a touch taller than the 24 pt menu bar, so it
    /// reads as an island rather than a menu-bar item, without covering window content.
    static let virtualHeight: CGFloat = 28

    static func current() -> NotchLayout? {
        let forced = ProcessInfo.processInfo.environment["PRAYER_FORCE_ISLAND"] != nil
        if !forced, let screen = NSScreen.builtInWithNotch, let notch = screen.notchSize {
            return NotchLayout(screen: screen, notchSize: notch, isVirtual: false)
        }
        // screens.first is the display that carries the menu bar.
        guard let screen = NSScreen.screens.first else { return nil }
        return NotchLayout(screen: screen, notchSize: CGSize(width: 0, height: virtualHeight), isVirtual: true)
    }

    func matches(_ other: NotchLayout) -> Bool {
        screen.displayID == other.screen.displayID && isVirtual == other.isVirtual
    }
}
