import AppKit
import Combine

/// Menu-bar item: the fallback UI on Macs without a notch, and the home of Settings / Quit.
@MainActor
final class StatusItemController {
    private let app: AppState
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var cancellable: AnyCancellable?
    private let openSettings: () -> Void
    private let togglePanel: () -> Void
    /// When true (no notch) the item also shows the next prayer and countdown as text.
    var showsText = false { didSet { refresh() } }
    var isVisible: Bool {
        get { item.isVisible }
        set { item.isVisible = newValue }
    }

    init(app: AppState, openSettings: @escaping () -> Void, togglePanel: @escaping () -> Void) {
        self.app = app
        self.openSettings = openSettings
        self.togglePanel = togglePanel

        item.button?.image = NSImage(systemSymbolName: "moon.stars", accessibilityDescription: "Prayer")
        item.button?.imagePosition = .imageLeading
        item.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        rebuildMenu()
        refresh()

        cancellable = app.$now
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.addItem(ClosureMenuItem(title: app.strings.openSettings, key: ",") { [openSettings] in openSettings() })
        menu.addItem(ClosureMenuItem(title: app.strings.showPanel, key: "p") { [togglePanel] in togglePanel() })
        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem(title: app.strings.quit, key: "q") { NSApp.terminate(nil) })
        item.menu = menu
    }

    private func refresh() {
        guard showsText, let s = app.snapshot else {
            item.button?.title = ""
            return
        }
        let remaining = s.remaining(at: app.now)
        let total = Int(remaining.rounded(.up))
        let h = total / 3600, m = (total % 3600) / 60
        let short = h > 0 ? String(format: "%d:%02d", h, m) : "\(max(m, 1))m"
        item.button?.title = " \(app.strings.prayer(s.next.prayer)) · \(short)"
    }
}

final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(title: String, key: String = "", handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(fire), keyEquivalent: key)
        target = self
    }

    required init(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    @objc private func fire() { handler() }
}
