import Foundation
import Adhan

/// Minimal bilingual strings. Latin digits are kept in both languages for the mono look.
struct Strings {
    let ar: Bool

    static func effectiveLanguage(_ setting: AppLanguage) -> AppLanguage {
        switch setting {
        case .system:
            let pref = Locale.preferredLanguages.first ?? "en"
            return pref.hasPrefix("ar") ? .arabic : .english
        default:
            return setting
        }
    }

    func prayer(_ p: Prayer) -> String {
        switch p {
        case .fajr:    return ar ? "الفجر"  : "Fajr"
        case .sunrise: return ar ? "الشروق" : "Sunrise"
        case .dhuhr:   return ar ? "الظهر"  : "Dhuhr"
        case .asr:     return ar ? "العصر"  : "Asr"
        case .maghrib: return ar ? "المغرب" : "Maghrib"
        case .isha:    return ar ? "العشاء" : "Isha"
        }
    }

    func method(_ m: CalculationMethod) -> String {
        switch m {
        case .muslimWorldLeague:     return ar ? "رابطة العالم الإسلامي" : "Muslim World League"
        case .egyptian:              return ar ? "الهيئة المصرية العامة للمساحة" : "Egyptian General Authority"
        case .karachi:               return ar ? "جامعة العلوم الإسلامية، كراتشي" : "Univ. of Islamic Sciences, Karachi"
        case .ummAlQura:             return ar ? "جامعة أم القرى" : "Umm al-Qura"
        case .dubai:                 return ar ? "الإمارات (دبي)" : "UAE (Dubai)"
        case .moonsightingCommittee: return ar ? "لجنة رؤية الهلال" : "Moonsighting Committee"
        case .northAmerica:          return ar ? "أمريكا الشمالية (ISNA)" : "North America (ISNA)"
        case .kuwait:                return ar ? "الكويت" : "Kuwait"
        case .qatar:                 return ar ? "قطر" : "Qatar"
        case .singapore:             return ar ? "سنغافورة" : "Singapore"
        case .tehran:                return ar ? "جامعة طهران" : "Univ. of Tehran"
        case .turkey:                return ar ? "ديانت (تركيا)" : "Diyanet (Turkey)"
        case .other:                 return ar ? "أخرى" : "Other"
        }
    }

    func methodShort(_ m: CalculationMethod) -> String {
        switch m {
        case .muslimWorldLeague:     return ar ? "رابطة العالم الإسلامي" : "MWL"
        case .egyptian:              return ar ? "الهيئة المصرية" : "Egyptian Authority"
        case .karachi:               return ar ? "كراتشي" : "Karachi"
        case .ummAlQura:             return ar ? "أم القرى" : "Umm al-Qura"
        case .dubai:                 return ar ? "دبي" : "Dubai"
        case .moonsightingCommittee: return ar ? "رؤية الهلال" : "Moonsighting"
        case .northAmerica:          return "ISNA"
        case .kuwait:                return ar ? "الكويت" : "Kuwait"
        case .qatar:                 return ar ? "قطر" : "Qatar"
        case .singapore:             return ar ? "سنغافورة" : "Singapore"
        case .tehran:                return ar ? "طهران" : "Tehran"
        case .turkey:                return ar ? "ديانت" : "Diyanet"
        case .other:                 return ar ? "أخرى" : "Other"
        }
    }

    func madhab(_ m: Madhab) -> String {
        switch m {
        case .shafi:  return ar ? "شافعي / مالكي / حنبلي" : "Shafi, Maliki, Hanbali"
        case .hanafi: return ar ? "حنفي" : "Hanafi"
        }
    }

    var nextPrayer: String { ar ? "الصلاة القادمة" : "Next Prayer" }
    var now: String { ar ? "الآن" : "Now" }
    var inPrefix: String { ar ? "بعد" : "In" }
    var minutesShort: String { ar ? "د" : "min" }
    var hoursShort: String { ar ? "س" : "h" }
    var locating: String { ar ? "جارٍ تحديد الموقع…" : "Locating…" }
    var noLocation: String { ar ? "حدّد موقعك" : "Set Your Location" }
    var noLocationShort: String { ar ? "الموقع" : "Location" }
    var showMenuBarIcon: String { ar ? "إظهار أيقونة في شريط القوائم" : "Show Menu Bar Icon" }
    var locationDenied: String { ar ? "الوصول للموقع مرفوض. اختر مدينة يدويًا." : "Location access denied. Choose a city manually." }
    var locationFailed: String { ar ? "تعذّر تحديد الموقع. اختر مدينة يدويًا." : "Could not locate you. Choose a city manually." }
    var automatic: String { ar ? "تلقائي" : "Automatic" }
    var autoByCountry: String { ar ? "تلقائي (حسب الدولة)" : "Automatic (by country)" }
    var settings: String { ar ? "الإعدادات" : "Settings" }
    var location: String { ar ? "الموقع" : "Location" }
    var useMyLocation: String { ar ? "استخدم موقعي" : "Use My Location" }
    var chooseCity: String { ar ? "اختيار مدينة" : "Choose a City" }
    var searchCity: String { ar ? "ابحث عن مدينة…" : "Search for a city…" }
    var currentLocation: String { ar ? "الموقع الحالي" : "Current Location" }
    var calculation: String { ar ? "الحساب" : "Calculation" }
    var method: String { ar ? "طريقة الحساب" : "Method" }
    var asrMadhab: String { ar ? "مذهب العصر" : "Asr (madhab)" }
    var display: String { ar ? "العرض" : "Display" }
    var timeFormat: String { ar ? "تنسيق الوقت" : "Time Format" }
    var systemDefault: String { ar ? "حسب النظام" : "System" }
    var twelveHour: String { ar ? "12 ساعة" : "12-hour" }
    var twentyFourHour: String { ar ? "24 ساعة" : "24-hour" }
    var language: String { ar ? "اللغة" : "Language" }
    var arabic: String { "العربية" }
    var english: String { "English" }
    var general: String { ar ? "عام" : "General" }
    var launchAtLogin: String { ar ? "التشغيل عند بدء النظام" : "Launch at Login" }
    var quit: String { ar ? "إنهاء" : "Quit" }
    var openSettings: String { ar ? "الإعدادات…" : "Settings…" }
    var showPanel: String { ar ? "تثبيت لوحة النوتش" : "Pin notch panel" }
    var timeZone: String { ar ? "المنطقة الزمنية" : "Time zone" }
    var searching: String { ar ? "جارٍ البحث…" : "Searching…" }
    var noResults: String { ar ? "لا توجد نتائج" : "No results" }
    var today: String { ar ? "اليوم" : "Today" }
    var updates: String { ar ? "التحديثات" : "Updates" }
    var checkForUpdates: String { ar ? "فحص التحديثات" : "Check for Updates" }
    var daily: String { ar ? "يوميًا" : "Daily" }
    var weekly: String { ar ? "أسبوعيًا" : "Weekly" }
    var never: String { ar ? "أبدًا" : "Never" }
    var checkNow: String { ar ? "افحص الآن" : "Check Now" }
    var installUpdate: String { ar ? "تثبيت" : "Install" }
    var autoInstallUpdates: String { ar ? "تثبيت التحديثات تلقائيًا" : "Install Updates Automatically" }
    var checking: String { ar ? "جارٍ الفحص…" : "Checking…" }
    var upToDate: String { ar ? "أحدث إصدار" : "Up to Date" }
    var updateAvailable: String { ar ? "إصدار جديد متاح" : "Update Available" }
    var downloading: String { ar ? "جارٍ التنزيل" : "Downloading" }
    var installing: String { ar ? "جارٍ التثبيت" : "Installing" }
    var updateFailed: String { ar ? "فشل التحديث" : "Update failed" }
    var lastChecked: String { ar ? "آخر فحص" : "Last Checked" }
    var version: String { ar ? "الإصدار" : "Version" }
    var notBundled: String { ar ? "التحديث التلقائي يعمل من نسخة .app فقط" : "Self-update only works from a built .app" }
    var tomorrow: String { ar ? "غدًا" : "Tomorrow" }
}
