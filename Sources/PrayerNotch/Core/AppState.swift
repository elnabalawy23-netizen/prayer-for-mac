import Foundation
import Combine
import SwiftUI
import Adhan

@MainActor
final class AppState: ObservableObject {
    @Published var settings: AppSettings {
        didSet {
            guard settings != oldValue else { return }
            settings.save()
            if settings.locationMode != oldValue.locationMode, settings.locationMode == .automatic {
                refreshLocation()
            }
            recompute()
        }
    }
    @Published private(set) var autoLocation: PlaceLocation?
    @Published private(set) var snapshot: PrayerSnapshot?
    @Published private(set) var now = Date()
    @Published private(set) var isLocating = false
    @Published private(set) var locationFailure: LocationService.Failure?

    var openSettings: (() -> Void)?
    /// Fixed "now" for previews (DebugRenderer); nil in normal use.
    var timeOverride: Date? { didSet { now = timeOverride ?? Date(); recompute() } }

    private let locationService = LocationService()
    private var timer: Timer?
    private static let autoLocationKey = "prayernotch.autoLocation.v1"

    init() {
        settings = AppSettings.load()
        if let data = UserDefaults.standard.data(forKey: Self.autoLocationKey),
           let cached = try? JSONDecoder().decode(PlaceLocation.self, from: data) {
            autoLocation = cached
        }

        locationService.onLocation = { [weak self] place in
            guard let self else { return }
            self.isLocating = false
            self.locationFailure = nil
            self.autoLocation = place
            if let data = try? JSONEncoder().encode(place) {
                UserDefaults.standard.set(data, forKey: Self.autoLocationKey)
            }
            self.recompute()
        }
        locationService.onFailure = { [weak self] failure in
            guard let self else { return }
            self.isLocating = false
            self.locationFailure = failure
        }

        recompute()
        refreshLocation()

        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    // MARK: - Derived

    var location: PlaceLocation? {
        settings.locationMode == .manual ? settings.manualLocation : autoLocation
    }

    var language: AppLanguage { Strings.effectiveLanguage(settings.language) }
    var isArabic: Bool { language == .arabic }
    var strings: Strings { Strings(ar: isArabic) }

    var resolvedMethod: CalculationMethod? { snapshot?.method }

    // MARK: - Actions

    func refreshLocation() {
        guard settings.locationMode == .automatic else { return }
        isLocating = true
        locationFailure = nil
        locationService.request()
    }

    func recompute() {
        guard let loc = location else { snapshot = nil; return }
        snapshot = PrayerEngine.snapshot(at: timeOverride ?? Date(), settings: settings, location: loc)
    }

    private func tick() {
        if timeOverride != nil { return }
        now = Date()
        if let s = snapshot, now >= s.validUntil { recompute() }
    }

    // MARK: - Typography

    /// Display font: SF for English, Almarai (bundled) for Arabic.
    func display(_ size: CGFloat, weight: Font.Weight = .light) -> Font {
        guard isArabic else { return .system(size: size, weight: weight) }
        let name: String
        if weight == .ultraLight || weight == .thin || weight == .light {
            name = "Almarai-Light"
        } else if weight == .semibold || weight == .bold || weight == .heavy || weight == .black {
            name = "Almarai-Bold"
        } else {
            name = "Almarai-Regular"
        }
        return .custom(name, size: size)
    }

    // MARK: - Formatting

    private var uses24h: Bool {
        switch settings.timeFormat {
        case .twelveHour: return false
        case .twentyFourHour: return true
        case .system:
            let fmt = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? ""
            return !fmt.contains("a")
        }
    }

    private var numberLocale: Locale {
        Locale(identifier: isArabic ? "ar_EG@numbers=latn" : "en_US_POSIX")
    }

    func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = numberLocale
        f.timeZone = location?.timeZone ?? .current
        f.dateFormat = uses24h ? "HH:mm" : "h:mm"
        return f.string(from: date)
    }

    func formatPeriod(_ date: Date) -> String? {
        guard !uses24h else { return nil }
        let f = DateFormatter()
        f.locale = numberLocale
        f.timeZone = location?.timeZone ?? .current
        f.dateFormat = "a"
        return f.string(from: date)
    }

    func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: isArabic ? "ar_EG@numbers=latn" : "en_US")
        f.timeZone = location?.timeZone ?? .current
        f.dateFormat = "EEE d MMM"
        return f.string(from: date)
    }

    /// "00:14:22" – always eight characters for a stable mono layout.
    func countdown(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded(.down))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    /// "02:08" – hours and minutes only, for the compact strip beside the notch.
    func countdownShort(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded(.up))
        let h = total / 3600, m = (total % 3600) / 60
        return String(format: "%02d:%02d", h, m)
    }

    /// "in 14 min" / "in 2h 05m"
    func relative(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded(.up))
        let h = total / 3600, m = (total % 3600) / 60
        let s = strings
        if isArabic {
            if h == 0 { return "بعد \(max(m, 1)) دقيقة" }
            return "بعد \(h) س \(m) د"
        }
        if h == 0 { return "\(s.inPrefix) \(max(m, 1)) \(s.minutesShort)" }
        return "\(s.inPrefix) \(h)\(s.hoursShort) \(String(format: "%02d", m))\(s.minutesShort)"
    }
}
