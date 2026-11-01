import SwiftUI
import Adhan

/// Warm, time-of-day tinted glow that lives inside the black surface.
struct Palette: Equatable {
    let glow: Color
    let deep: Color
    let accent: Color

    static func hex(_ v: UInt32) -> Color {
        Color(red: Double((v >> 16) & 0xFF) / 255,
              green: Double((v >> 8) & 0xFF) / 255,
              blue: Double(v & 0xFF) / 255)
    }

    /// Keyed by the prayer we are counting down to: each prayer gets its own colour against the black.
    static func forNext(_ prayer: Prayer) -> Palette {
        switch prayer {
        case .fajr:    return Palette(glow: hex(0x2F4BB8), deep: hex(0x0E1440), accent: hex(0xA9BDFF)) // night → dawn: indigo blue
        case .sunrise: return Palette(glow: hex(0xD98B4A), deep: hex(0x4A2510), accent: hex(0xFFC79A)) // (not used as "next")
        case .dhuhr:   return Palette(glow: hex(0xD6B23A), deep: hex(0x4A3A0E), accent: hex(0xFFE38A)) // morning: gold
        case .asr:     return Palette(glow: hex(0xE0802A), deep: hex(0x4C2A0C), accent: hex(0xFFC08A)) // afternoon: orange
        case .maghrib: return Palette(glow: hex(0xB83A1B), deep: hex(0x4A150A), accent: hex(0xFF9A66)) // sunset: burnt sienna
        case .isha:    return Palette(glow: hex(0x7A2E6E), deep: hex(0x26102C), accent: hex(0xF0A0E8)) // dusk: plum
        }
    }

    static let idle = Palette(glow: hex(0x5A4A3A), deep: hex(0x1A1512), accent: hex(0xD8C8B8))
}

extension Prayer {
    /// SF Symbol for each prayer's moment of the day.
    var symbolName: String {
        switch self {
        case .fajr:    return "sun.horizon"
        case .sunrise: return "sunrise"
        case .dhuhr:   return "sun.max"
        case .asr:     return "sun.min"
        case .maghrib: return "sunset"
        case .isha:    return "moon.stars"
        }
    }
}

struct Hairline: View {
    var opacity: Double = 0.10
    var body: some View {
        Rectangle().fill(Color.white.opacity(opacity)).frame(height: 1)
    }
}

extension Font {
    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    static func display(_ size: CGFloat, weight: Font.Weight = .light) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

/// Small caption: mono with light tracking in English (Title Case, never all caps),
/// Almarai without tracking in Arabic so the letters stay connected.
struct CaptionStyle: ViewModifier {
    @EnvironmentObject var app: AppState
    let size: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        if app.isArabic {
            content
                .font(app.display(size + 2, weight: .regular))
                .foregroundStyle(.white.opacity(min(1, opacity + 0.1)))
        } else {
            content
                .font(.mono(size))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(opacity))
        }
    }
}

/// Label inside a pill button.
struct PillLabelStyle: ViewModifier {
    @EnvironmentObject var app: AppState
    func body(content: Content) -> some View {
        if app.isArabic {
            content.font(app.display(11.5, weight: .bold))
        } else {
            content.font(.mono(10, weight: .semibold)).tracking(1.2)
        }
    }
}

extension View {
    func caption(_ size: CGFloat = 9.5, opacity: Double = 0.45) -> some View {
        modifier(CaptionStyle(size: size, opacity: opacity))
    }
    func pillLabel() -> some View { modifier(PillLabelStyle()) }
}
