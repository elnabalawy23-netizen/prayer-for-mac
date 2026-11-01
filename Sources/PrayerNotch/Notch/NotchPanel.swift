import AppKit
import SwiftUI

/// Borderless, non-activating, always-on-top panel that sits over the notch area.
final class NotchPanel: NSPanel {
    init(frame: NSRect) {
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isFloatingPanel = true
        level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        acceptsMouseMovedEvents = true
        animationBehavior = .none
        isReleasedWhenClosed = false
        titleVisibility = .hidden
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Hosting view that only accepts clicks inside the drawn notch shape, so the
/// transparent margins of the panel never swallow clicks meant for the menu bar.
final class NotchHostingView<Content: View>: NSHostingView<Content> {
    var hitRect: (() -> CGRect)?

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let rect = hitRect?(), rect.contains(point) else { return nil }
        return super.hitTest(point)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
