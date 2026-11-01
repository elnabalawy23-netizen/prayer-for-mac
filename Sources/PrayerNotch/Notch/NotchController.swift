import AppKit
import SwiftUI

@MainActor
final class NotchUIState: ObservableObject {
    @Published var isExpanded = false
    @Published var isPinned = false
    @Published var notchSize = CGSize(width: 200, height: 32)
    /// True on Macs without a notch: the strip is a self-contained island with no center gap.
    @Published var isVirtual = false
    /// Physical left / right wing widths beside the notch. Each is sized from its own
    /// content plus an even margin, so the text sits centered in its wing.
    @Published var leftWingWidth: CGFloat = 100
    @Published var rightWingWidth: CGFloat = 80
    static let wingMargin: CGFloat = 20
    static let minWingWidth: CGFloat = 80
    var onTap: (() -> Void)?

    var collapsedSize: CGSize {
        CGSize(width: notchSize.width + leftWingWidth + rightWingWidth, height: notchSize.height)
    }

    /// Horizontal shift of the collapsed strip that keeps the gap between the wings
    /// exactly over the physical notch when the wings differ in width.
    var collapsedOffsetX: CGFloat { isVirtual ? 0 : (rightWingWidth - leftWingWidth) / 2 }
}

/// Owns the notch panel, tracks the mouse and drives expand / collapse.
@MainActor
final class NotchController {
    static let expandedSize = CGSize(width: 540, height: 222)
    private static let margin: CGFloat = 24

    let ui = NotchUIState()
    private let app: AppState
    private let panel: NotchPanel
    private let layout: NotchLayout
    private var screen: NSScreen { layout.screen }
    var isVirtual: Bool { layout.isVirtual }
    private var monitors: [Any] = []
    private var collapseWork: DispatchWorkItem?
    private var expandWork: DispatchWorkItem?

    init?(app: AppState) {
        guard let layout = NotchLayout.current() else { return nil }
        self.app = app
        self.layout = layout
        self.ui.notchSize = layout.notchSize
        self.ui.isVirtual = layout.isVirtual
        self.panel = NotchPanel(frame: Self.panelFrame(on: layout.screen), overFullScreen: !layout.isVirtual)

        let root = NotchRootView().environmentObject(app).environmentObject(ui)
        let host = NotchHostingView(rootView: root)
        host.hitRect = { [weak self] in
            guard let self else { return .zero }
            return self.shapeRectInWindow(expanded: self.ui.isExpanded)
        }
        panel.contentView = host
        ui.onTap = { [weak self] in self?.togglePinned() }
        panel.orderFrontRegardless()
        installMonitors()
        NSLog("[notch] %@ screen=%@ notch=%@ panel=%@ collapsed=%@", layout.isVirtual ? "virtual island" : "hardware notch", NSStringFromRect(screen.frame), NSStringFromSize(layout.notchSize), NSStringFromRect(panel.frame), NSStringFromRect(shapeRectOnScreen(expanded: false)))
    }

    /// Still the right home after a display change (same screen, same kind of island)?
    var isValidForCurrentScreens: Bool {
        guard let now = NotchLayout.current() else { return false }
        return now.matches(layout)
    }

    func relayout() {
        if let now = NotchLayout.current(), now.matches(layout) { ui.notchSize = now.notchSize }
        panel.setFrame(Self.panelFrame(on: screen), display: true)
    }

    func close() {
        monitors.forEach { NSEvent.removeMonitor($0) }
        monitors = []
        panel.orderOut(nil)
    }

    func togglePinned() {
        ui.isPinned.toggle()
        setExpanded(ui.isPinned)
    }

    func setExpanded(_ expanded: Bool) {
        collapseWork?.cancel(); collapseWork = nil
        expandWork?.cancel(); expandWork = nil
        guard ui.isExpanded != expanded else { return }
        ui.isExpanded = expanded
    }

    // MARK: - Geometry

    private static func panelFrame(on screen: NSScreen) -> NSRect {
        let w = expandedSize.width + margin * 2
        let h = expandedSize.height + margin
        return NSRect(x: (screen.frame.midX - w / 2).rounded(), y: screen.frame.maxY - h, width: w, height: h)
    }

    /// Rect of the visible shape in window coordinates (origin bottom-left).
    func shapeRectInWindow(expanded: Bool) -> CGRect {
        let s = expanded ? Self.expandedSize : ui.collapsedSize
        let dx = expanded ? 0 : ui.collapsedOffsetX
        let f = panel.frame
        return CGRect(x: ((f.width - s.width) / 2 + dx).rounded(), y: f.height - s.height, width: s.width, height: s.height)
    }

    func shapeRectOnScreen(expanded: Bool) -> CGRect {
        shapeRectInWindow(expanded: expanded).offsetBy(dx: panel.frame.minX, dy: panel.frame.minY)
    }

    // MARK: - Mouse tracking

    private func installMonitors() {
        let handle = { [weak self] in
            MainActor.assumeIsolated { self?.mouseMoved() }
        }
        if let m = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { _ in handle() } {
            monitors.append(m)
        }
        if let m = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { event in handle(); return event } {
            monitors.append(m)
        }
    }

    private func mouseMoved() {
        let p = NSEvent.mouseLocation
        if ui.isExpanded {
            let r = shapeRectOnScreen(expanded: true).insetBy(dx: -18, dy: -18)
            if r.contains(p) {
                collapseWork?.cancel(); collapseWork = nil
            } else if !ui.isPinned {
                scheduleCollapse()
            }
        } else {
            let r = shapeRectOnScreen(expanded: false).insetBy(dx: 0, dy: -2)
            if r.contains(p) {
                scheduleExpand()
            } else {
                expandWork?.cancel(); expandWork = nil
            }
        }
    }

    private func scheduleExpand() {
        guard expandWork == nil else { return }
        expandWork = after(0.1) { [weak self] in
            self?.expandWork = nil
            self?.setExpanded(true)
        }
    }

    private func scheduleCollapse() {
        guard collapseWork == nil else { return }
        collapseWork = after(0.28) { [weak self] in
            self?.collapseWork = nil
            self?.setExpanded(false)
        }
    }

    private func after(_ seconds: Double, _ work: @escaping @MainActor () -> Void) -> DispatchWorkItem {
        let item = DispatchWorkItem { MainActor.assumeIsolated { work() } }
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: item)
        return item
    }
}
