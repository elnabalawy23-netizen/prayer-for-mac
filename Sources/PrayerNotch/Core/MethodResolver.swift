import Foundation
import Adhan

/// Picks the official calculation convention for a country so the times match
/// what local authorities publish (Umm al-Qura for Saudi, Egyptian Authority for Egypt, ...).
enum MethodResolver {
    static func method(for countryCode: String) -> CalculationMethod {
        switch countryCode.uppercased() {
        case "SA", "BH", "OM", "YE":                         return .ummAlQura
        case "EG", "SD", "LY", "IQ", "SY", "LB", "JO", "PS": return .egyptian
        case "AE":                                           return .dubai
        case "QA":                                           return .qatar
        case "KW":                                           return .kuwait
        case "TR":                                           return .turkey
        case "IR":                                           return .tehran
        case "PK", "IN", "BD", "AF", "NP", "LK":             return .karachi
        case "SG", "MY", "ID", "BN":                         return .singapore
        case "US", "CA", "MX":                               return .northAmerica
        case "GB", "IE":                                     return .moonsightingCommittee
        default:                                             return .muslimWorldLeague
        }
    }

    static func madhab(for countryCode: String) -> Madhab {
        switch countryCode.uppercased() {
        case "PK", "IN", "BD", "AF", "TR", "UZ", "KZ", "KG", "TJ", "TM", "AZ",
             "BA", "AL", "XK", "MK", "RU", "CN":
            return .hanafi
        default:
            return .shafi
        }
    }
}
