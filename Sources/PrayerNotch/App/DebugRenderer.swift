import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// `Prayer --render <outDir> <name> <countryCode> <lat> <lon> <tz>` renders the collapsed and
/// expanded notch views to PNG files so the design can be reviewed without screen capture.
enum DebugRenderer {
    @MainActor
    static func run(arguments: [String]) {
        guard let i = arguments.firstIndex(of: "--render"), arguments.count >= i + 7 else {
            print("usage: --render <outDir> <name> <countryCode> <lat> <lon> <timeZoneID>")
            return
        }
        let a = Array(arguments[(i + 1)...])
        let outDir = URL(fileURLWithPath: a[0])
        let loc = PlaceLocation(name: a[1], country: "", countryCode: a[2],
                                latitude: Double(a[3]) ?? 0, longitude: Double(a[4]) ?? 0, timeZoneID: a[5])

        let app = AppState()
        if let lang = ProcessInfo.processInfo.environment["PRAYER_RENDER_LANG"] {
            app.settings.language = lang == "ar" ? .arabic : .english
        }
        app.settings.locationMode = .manual
        app.settings.manualLocation = loc
        app.recompute()

        let ui = NotchUIState()
        ui.notchSize = NSScreen.builtInWithNotch?.notchSize ?? CGSize(width: 200, height: 32)

        for expanded in [false, true] {
            ui.isExpanded = expanded
            let size = expanded ? NotchController.expandedSize : ui.collapsedSize
            let canvas = CGSize(width: size.width + 80, height: size.height + 60)
            let view = ZStack(alignment: .top) {
                LinearGradient(colors: [Color(white: 0.92), Color(white: 0.82)], startPoint: .top, endPoint: .bottom)
                NotchRootView().environmentObject(app).environmentObject(ui)
            }
            .frame(width: canvas.width, height: canvas.height)
            .transaction { $0.animation = nil }

            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            guard let cg = renderer.cgImage else { print("render failed"); continue }
            let url = outDir.appendingPathComponent(expanded ? "notch-expanded.png" : "notch-collapsed.png")
            if let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) {
                CGImageDestinationAddImage(dest, cg, nil)
                CGImageDestinationFinalize(dest)
                print("wrote \(url.path)")
            }
        }
    }
}
