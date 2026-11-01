import Foundation
import CoreLocation

/// Looks up the Arabic and English names of a place so the UI can show the city in its own language.
enum PlaceNames {
    static func lookup(latitude: Double, longitude: Double) async -> [String: String] {
        var out: [String: String] = [:]
        let location = CLLocation(latitude: latitude, longitude: longitude)
        for code in ["ar", "en"] {
            let geocoder = CLGeocoder()
            guard let p = try? await geocoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: code)).first else { continue }
            if let city = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea { out[code] = city }
            if let country = p.country { out["\(code)_country"] = country }
        }
        return out
    }
}
