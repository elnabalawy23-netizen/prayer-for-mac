import Foundation
import Adhan

struct PrayerSlot: Identifiable, Equatable {
    let prayer: Prayer
    let time: Date
    /// 0 = the base prayer day, 1 = the following day.
    let dayOffset: Int
    var id: String { "\(dayOffset)-\(prayer)" }
}

/// One stretch of the day's timeline, from one prayer to the next.
struct TimelineSegment: Identifiable {
    let start: PrayerSlot
    let end: PrayerSlot
    var id: String { start.id }

    func progress(at now: Date) -> Double {
        let total = end.time.timeIntervalSince(start.time)
        guard total > 0 else { return 0 }
        return min(1, max(0, now.timeIntervalSince(start.time) / total))
    }
}

/// Everything the UI needs for the current "prayer day" (Fajr to the next Fajr).
struct PrayerSnapshot {
    let location: PlaceLocation
    let method: CalculationMethod
    let madhab: Madhab
    /// Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha of the base day.
    let daySlots: [PrayerSlot]
    let nextDayFajr: PrayerSlot
    /// The last prayer that has begun (sunrise excluded).
    let previous: PrayerSlot
    /// The next prayer to come (sunrise excluded).
    let next: PrayerSlot

    var validUntil: Date { next.time }

    var segments: [TimelineSegment] {
        let points = daySlots + [nextDayFajr]
        return zip(points, points.dropFirst()).map { TimelineSegment(start: $0, end: $1) }
    }

    func remaining(at now: Date) -> TimeInterval { max(0, next.time.timeIntervalSince(now)) }

    func progress(at now: Date) -> Double {
        let total = next.time.timeIntervalSince(previous.time)
        guard total > 0 else { return 0 }
        return min(1, max(0, now.timeIntervalSince(previous.time) / total))
    }

    func slot(for prayer: Prayer) -> PrayerSlot? { daySlots.first { $0.prayer == prayer } }
}

enum PrayerEngine {
    static func resolve(settings: AppSettings, location: PlaceLocation)
        -> (params: CalculationParameters, method: CalculationMethod, madhab: Madhab) {
        let method = settings.methodOverride ?? MethodResolver.method(for: location.countryCode)
        let madhab = settings.madhabOverride ?? MethodResolver.madhab(for: location.countryCode)
        var params = method.params
        params.madhab = madhab
        params.highLatitudeRule = HighLatitudeRule.recommended(for: location.coordinates)
        return (params, method, madhab)
    }

    static func calendar(for location: PlaceLocation) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = location.timeZone
        return cal
    }

    static func times(on day: Date, location: PlaceLocation, params: CalculationParameters) -> PrayerTimes? {
        let cal = calendar(for: location)
        let comps = cal.dateComponents([.year, .month, .day], from: day)
        return PrayerTimes(coordinates: location.coordinates, date: comps, calculationParameters: params)
    }

    static func snapshot(at now: Date, settings: AppSettings, location: PlaceLocation) -> PrayerSnapshot? {
        let (params, method, madhab) = resolve(settings: settings, location: location)
        let cal = calendar(for: location)

        guard let today = times(on: now, location: location, params: params) else { return nil }

        // The prayer day runs Fajr → next Fajr. Before today's Fajr we are still in yesterday's day.
        var baseDay = now
        if now < today.fajr, let yesterday = cal.date(byAdding: .day, value: -1, to: now) {
            baseDay = yesterday
        }
        guard let base = times(on: baseDay, location: location, params: params),
              let nextDate = cal.date(byAdding: .day, value: 1, to: baseDay),
              let nextDay = times(on: nextDate, location: location, params: params) else { return nil }

        let daySlots = Prayer.allCases.map { PrayerSlot(prayer: $0, time: base.time(for: $0), dayOffset: 0) }
        let nextFajr = PrayerSlot(prayer: .fajr, time: nextDay.fajr, dayOffset: 1)

        let sequence = daySlots.filter { $0.prayer != .sunrise } + [nextFajr]
        let next = sequence.first { $0.time > now } ?? nextFajr
        let previous = sequence.last { $0.time <= now } ?? daySlots[0]

        return PrayerSnapshot(location: location, method: method, madhab: madhab,
                              daySlots: daySlots, nextDayFajr: nextFajr,
                              previous: previous, next: next)
    }
}
