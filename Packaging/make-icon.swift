// Draws the app icon with AppKit and writes an .iconset folder.
// Usage: swift Packaging/make-icon.swift <output.iconset>
import AppKit

let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/AppIcon.iconset")
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    NSColor(calibratedRed: r, green: g, blue: b, alpha: a).cgColor
}

func render(px: Int) -> Data {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext

    // macOS icon grid: the squircle sits inside a ~10% margin.
    let margin = s * 0.10
    let tile = CGRect(x: margin, y: margin, width: s - 2 * margin, height: s - 2 * margin)
    let radius = tile.width * 0.2237
    let squircle = CGPath(roundedRect: tile, cornerWidth: radius, cornerHeight: radius, transform: nil)

    // Black glass tile with a soft shadow.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.01), blur: s * 0.02, color: rgba(0, 0, 0, 0.35))
    ctx.addPath(squircle)
    ctx.setFillColor(rgba(0.04, 0.035, 0.035))
    ctx.fillPath()
    ctx.restoreGState()

    // Warm burnt-sienna glow, like the notch panel at Maghrib.
    ctx.saveGState()
    ctx.addPath(squircle)
    ctx.clip()
    let space = CGColorSpaceCreateDeviceRGB()
    let glow = CGGradient(colorsSpace: space, colors: [rgba(0.76, 0.30, 0.11, 0.95), rgba(0.76, 0.30, 0.11, 0)] as CFArray, locations: [0, 1])!
    let gc1 = CGPoint(x: tile.maxX - tile.width * 0.16, y: tile.minY + tile.height * 0.10)
    ctx.drawRadialGradient(glow, startCenter: gc1, startRadius: 0, endCenter: gc1, endRadius: tile.width * 0.78, options: [])
    let deep = CGGradient(colorsSpace: space, colors: [rgba(0.30, 0.10, 0.04, 0.9), rgba(0.30, 0.10, 0.04, 0)] as CFArray, locations: [0, 1])!
    let gc2 = CGPoint(x: tile.minX + tile.width * 0.18, y: tile.minY + tile.height * 0.04)
    ctx.drawRadialGradient(deep, startCenter: gc2, startRadius: 0, endCenter: gc2, endRadius: tile.width * 0.62, options: [])
    ctx.restoreGState()

    // Thin crescent: a white disc with an offset disc knocked out.
    ctx.saveGState()
    ctx.addPath(squircle)
    ctx.clip()
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    let r = tile.width * 0.21
    let c = CGPoint(x: tile.minX + tile.width * 0.42, y: tile.minY + tile.height * 0.63)
    ctx.setFillColor(rgba(1, 1, 1, 0.96))
    ctx.fillEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
    ctx.setBlendMode(.destinationOut)
    let r2 = r * 0.84
    let c2 = CGPoint(x: c.x + r * 0.40, y: c.y + r * 0.20)
    ctx.fillEllipse(in: CGRect(x: c2.x - r2, y: c2.y - r2, width: 2 * r2, height: 2 * r2))
    ctx.endTransparencyLayer()
    ctx.restoreGState()

    // The day timeline: six thin bars, the fourth mid-way in the accent colour.
    let barY = tile.minY + tile.height * 0.25
    let barH = max(1, tile.height * 0.03)
    let inset = tile.width * 0.15
    let gap = tile.width * 0.028
    let n = 6
    let w = (tile.width - 2 * inset - gap * CGFloat(n - 1)) / CGFloat(n)
    for i in 0..<n {
        let x = tile.minX + inset + CGFloat(i) * (w + gap)
        let rect = CGRect(x: x, y: barY, width: w, height: barH)
        ctx.setFillColor(rgba(1, 1, 1, i < 3 ? 0.78 : 0.20))
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: barH / 2, cornerHeight: barH / 2, transform: nil))
        ctx.fillPath()
        if i == 3 {
            let fill = CGRect(x: x, y: barY, width: w * 0.55, height: barH)
            ctx.setFillColor(rgba(1.0, 0.60, 0.40))
            ctx.addPath(CGPath(roundedRect: fill, cornerWidth: barH / 2, cornerHeight: barH / 2, transform: nil))
            ctx.fillPath()
        }
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for (points, scale) in [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2)] {
    let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
    try render(px: points * scale).write(to: outDir.appendingPathComponent(name))
}
print("Wrote iconset to \(outDir.path)")
