import Foundation
import Adhan

/// `Prayer --print <name> <countryCode> <lat> <lon> <tz> [yyyy-mm-dd]` prints the computed times.
enum DebugPrinter {
    static func run(arguments: [String]) {
        guard let i = arguments.firstIndex(of: "--print"), arguments.count >= i + 6 else {
            print("usage: --print <name> <countryCode> <lat> <lon> <timeZoneID> [yyyy-mm-dd]")
            return
        }
        let a = Array(arguments[(i + 1)...])
        let loc = PlaceLocation(name: a[0], country: "", countryCode: a[1],
                                latitude: Double(a[2]) ?? 0, longitude: Double(a[3]) ?? 0, timeZoneID: a[4])
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = loc.timeZone
        var day = Date()
        if a.count >= 6 {
            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = loc.timeZone
            day = f.date(from: a[5]) ?? day
        }
        let (params, method, madhab) = PrayerEngine.resolve(settings: AppSettings(), location: loc)
        guard let t = PrayerEngine.times(on: day, location: loc, params: params) else { print("no times"); return }
        let f = DateFormatter(); f.dateFormat = "HH:mm"; f.timeZone = loc.timeZone
        print("\(loc.name) [\(loc.countryCode)] method=\(method) madhab=\(madhab) tz=\(loc.timeZoneID) date=\(cal.dateComponents([.year,.month,.day], from: day))")
        for p in Prayer.allCases { print("  \(p): \(f.string(from: t.time(for: p)))") }
        if let snap = PrayerEngine.snapshot(at: Date(), settings: AppSettings(), location: loc) {
            print("  next: \(snap.next.prayer) at \(f.string(from: snap.next.time)) (day+\(snap.next.dayOffset)), previous: \(snap.previous.prayer)")
        }
    }
}
