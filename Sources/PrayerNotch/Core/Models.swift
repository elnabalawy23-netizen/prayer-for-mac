import Foundation
import Adhan

/// A resolved place: the city the user chose (or was located in),
/// with the coordinates and time zone that prayer times are computed against.
struct PlaceLocation: Codable, Equatable, Hashable {
    var name: String
    var country: String
    var countryCode: String
    var latitude: Double
    var longitude: Double
    var timeZoneID: String
    /// Localized names keyed "ar", "en", "ar_country", "en_country" (filled by PlaceNames).
    var names: [String: String] = [:]

    var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .current }
    var coordinates: Coordinates { Coordinates(latitude: latitude, longitude: longitude) }

    func displayName(arabic: Bool) -> String { names[arabic ? "ar" : "en"] ?? name }
    func displayCountry(arabic: Bool) -> String { names[arabic ? "ar_country" : "en_country"] ?? country }

    init(name: String, country: String, countryCode: String, latitude: Double, longitude: Double, timeZoneID: String, names: [String: String] = [:]) {
        self.name = name; self.country = country; self.countryCode = countryCode
        self.latitude = latitude; self.longitude = longitude; self.timeZoneID = timeZoneID; self.names = names
    }

    private enum CodingKeys: String, CodingKey { case name, country, countryCode, latitude, longitude, timeZoneID, names }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        country = try c.decode(String.self, forKey: .country)
        countryCode = try c.decode(String.self, forKey: .countryCode)
        latitude = try c.decode(Double.self, forKey: .latitude)
        longitude = try c.decode(Double.self, forKey: .longitude)
        timeZoneID = try c.decode(String.self, forKey: .timeZoneID)
        names = try c.decodeIfPresent([String: String].self, forKey: .names) ?? [:]
    }
}

enum LocationMode: String, Codable, CaseIterable { case automatic, manual }
enum TimeFormat: String, Codable, CaseIterable { case system, twelveHour, twentyFourHour }
enum AppLanguage: String, Codable, CaseIterable { case system, arabic, english }

struct AppSettings: Codable, Equatable {
    var locationMode: LocationMode = .automatic
    var manualLocation: PlaceLocation? = nil
    /// nil = pick automatically from the location's country.
    var methodOverride: CalculationMethod? = nil
    /// nil = pick automatically from the location's country.
    var madhabOverride: Madhab? = nil
    var timeFormat: TimeFormat = .system
    var language: AppLanguage = .english
    var launchAtLogin: Bool = false
    /// How often to look for a new release on GitHub (0 = never).
    var updateCheckDays: Int = 1
    var autoInstallUpdates: Bool = true
    /// On notch Macs the menu-bar icon is hidden unless this is on; on other Macs it is always shown.
    var showMenuBarIcon: Bool = false

    init() {}

    private enum CodingKeys: String, CodingKey {
        case locationMode, manualLocation, methodOverride, madhabOverride, timeFormat, language, launchAtLogin, showMenuBarIcon, updateCheckDays, autoInstallUpdates
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        locationMode = try c.decodeIfPresent(LocationMode.self, forKey: .locationMode) ?? .automatic
        manualLocation = try c.decodeIfPresent(PlaceLocation.self, forKey: .manualLocation)
        methodOverride = try c.decodeIfPresent(CalculationMethod.self, forKey: .methodOverride)
        madhabOverride = try c.decodeIfPresent(Madhab.self, forKey: .madhabOverride)
        timeFormat = try c.decodeIfPresent(TimeFormat.self, forKey: .timeFormat) ?? .system
        language = try c.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .english
        launchAtLogin = try c.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        showMenuBarIcon = try c.decodeIfPresent(Bool.self, forKey: .showMenuBarIcon) ?? false
        updateCheckDays = try c.decodeIfPresent(Int.self, forKey: .updateCheckDays) ?? 1
        autoInstallUpdates = try c.decodeIfPresent(Bool.self, forKey: .autoInstallUpdates) ?? true
    }

    static let storageKey = "prayernotch.settings.v3"

    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let s = try? JSONDecoder().decode(AppSettings.self, from: data) else { return AppSettings() }
        return s
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: AppSettings.storageKey)
        }
    }
}
