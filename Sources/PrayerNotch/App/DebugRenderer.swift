import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// `Prayer --render <outDir> <name> <countryCode> <lat> <lon> <tz>` renders the collapsed and
/// expanded notch views to PNG files so the design can be reviewed without screen capture.
/// `PRAYER_RENDER_ISLAND=1` renders the virtual island used on Macs without a notch.
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

        let env = ProcessInfo.processInfo.environment
        func makeApp(at time: Date?) -> AppState {
            let app = AppState()
            if let lang = env["PRAYER_RENDER_LANG"] {
                app.settings.language = lang == "ar" ? .arabic : .english
            }
            app.settings.locationMode = .manual
            app.settings.manualLocation = loc
            app.timeOverride = time
            app.recompute()
            return app
        }
        func date(_ hhmm: String) -> Date? {
            var cal = Calendar(identifier: .gregorian); cal.timeZone = loc.timeZone
            let parts = hhmm.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2 else { return nil }
            return cal.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: Date())
        }
        let island = env["PRAYER_RENDER_ISLAND"] != nil
        func makeUI() -> NotchUIState {
            let ui = NotchUIState()
            if island {
                ui.notchSize = CGSize(width: 0, height: NotchLayout.virtualHeight)
                ui.isVirtual = true
            } else {
                ui.notchSize = NSScreen.builtInWithNotch?.notchSize ?? CGSize(width: 200, height: 32)
            }
            return ui
        }
        let prefix = island ? "island" : "notch"
        if let list = env["PRAYER_RENDER_AT"] {
            let times = list.split(separator: ",").compactMap { date(String($0)) }
            let states: [(AppState, NotchUIState)] = times.map { t in
                let ui = makeUI()
                ui.isExpanded = true
                return (makeApp(at: t), ui)
            }
            let size = NotchController.expandedSize
            let canvas = CGSize(width: size.width + 80, height: (size.height + 24) * CGFloat(states.count) + 24)
            let view = VStack(spacing: 24) {
                ForEach(0..<states.count, id: \.self) { i in
                    NotchRootView().environmentObject(states[i].0).environmentObject(states[i].1)
                        .frame(width: size.width + 80, height: size.height)
                }
            }
            .padding(.vertical, 12)
            .frame(width: canvas.width, height: canvas.height)
            .background(LinearGradient(colors: [Color(white: 0.92), Color(white: 0.82)], startPoint: .top, endPoint: .bottom))
            .transaction { $0.animation = nil }
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            if let cg = renderer.cgImage {
                let url = outDir.appendingPathComponent("\(prefix)-palettes.png")
                if let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) {
                    CGImageDestinationAddImage(dest, cg, nil)
                    CGImageDestinationFinalize(dest)
                    print("wrote \(url.path)")
                }
            }
            return
        }

        let app = makeApp(at: nil)

        let ui = makeUI()

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
            let url = outDir.appendingPathComponent(expanded ? "\(prefix)-expanded.png" : "\(prefix)-collapsed.png")
            if let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) {
                CGImageDestinationAddImage(dest, cg, nil)
                CGImageDestinationFinalize(dest)
                print("wrote \(url.path)")
            }
        }
    }
}
