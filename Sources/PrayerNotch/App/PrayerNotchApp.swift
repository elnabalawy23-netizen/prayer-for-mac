import AppKit
import SwiftUI
import Combine

@main
struct PrayerNotchApp {
    static func main() {
        FontLoader.registerBundledFonts()
        if CommandLine.arguments.contains("--print") {
            DebugPrinter.run(arguments: CommandLine.arguments)
            return
        }
        if CommandLine.arguments.contains("--render") {
            MainActor.assumeIsolated { DebugRenderer.run(arguments: CommandLine.arguments) }
            return
        }
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var state: AppState!
    private var notch: NotchController?
    private var statusItem: StatusItemController!
    private var settingsWindow: SettingsWindowController!
    private var updater: Updater!
    private var settingsSink: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        state = AppState()
        updater = Updater(app: state)
        settingsWindow = SettingsWindowController(app: state, updater: updater)
        state.openSettings = { [weak self] in self?.settingsWindow.show() }

        statusItem = StatusItemController(
            app: state,
            openSettings: { [weak self] in self?.settingsWindow.show() },
            togglePanel: { [weak self] in self?.notch?.togglePinned() }
        )

        buildNotch()
        settingsSink = state.$settings
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in MainActor.assumeIsolated { self?.applyStatusItemVisibility() } }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.buildNotch() }
        }

        if state.location == nil && state.settings.locationMode == .manual {
            settingsWindow.show()
        }
    }

    private func buildNotch() {
        if let n = notch, n.isValidForCurrentScreens {
            n.relayout()
            return
        }
        notch?.close()
        notch = NotchController(app: state)
        applyStatusItemVisibility()
    }

    /// Nothing lives outside the notch on notch Macs unless the user opts in;
    /// Macs without a notch keep the text item as their only UI.
    private func applyStatusItemVisibility() {
        let hasNotch = notch != nil
        statusItem.showsText = !hasNotch
        statusItem.isVisible = !hasNotch || state.settings.showMenuBarIcon
    }
}
