import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let app: AppState
    private let updater: Updater
    private var window: NSWindow?

    init(app: AppState, updater: Updater) {
        self.app = app
        self.updater = updater
    }

    func show() {
        if window == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 760),
                             styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                             backing: .buffered, defer: false)
            w.title = app.strings.settings
            w.titlebarAppearsTransparent = true
            w.titleVisibility = .hidden
            w.isReleasedWhenClosed = false
            w.backgroundColor = NSColor(red: 0.043, green: 0.039, blue: 0.039, alpha: 1)
            w.contentView = NSHostingView(rootView: SettingsView().environmentObject(app).environmentObject(updater))
            w.center()
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
