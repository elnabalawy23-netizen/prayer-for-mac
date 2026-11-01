import AppKit
import CoreText

/// Registers the bundled Almarai family (Resources/Fonts) for this process.
enum FontLoader {
    static func registerBundledFonts() {
        var dirs: [URL] = []
        if let r = Bundle.main.resourceURL { dirs.append(r.appendingPathComponent("Fonts")) }
        // Running from `swift build` output: fall back to the source tree.
        dirs.append(URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources/Fonts"))
        for dir in dirs {
            guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil),
                  !files.isEmpty else { continue }
            for url in files where ["ttf", "otf"].contains(url.pathExtension.lowercased()) {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
            return
        }
    }
}
