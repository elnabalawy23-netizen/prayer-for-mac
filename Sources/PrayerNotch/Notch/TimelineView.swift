import SwiftUI
import Adhan

/// Six thin segments (Fajr→Sunrise→Dhuhr→Asr→Maghrib→Isha→Fajr) with a live fill,
/// echoing the stepped progress bars at the top of the reference screen.
struct TimelineView: View {
    @EnvironmentObject var app: AppState
    let snapshot: PrayerSnapshot
    let palette: Palette

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(snapshot.segments) { seg in
                SegmentView(segment: seg, snapshot: snapshot, palette: palette)
            }
        }
    }
}

private struct SegmentView: View {
    @EnvironmentObject var app: AppState
    let segment: TimelineSegment
    let snapshot: PrayerSnapshot
    let palette: Palette

    private var progress: Double { segment.progress(at: app.now) }
    private var isCurrent: Bool { progress > 0 && progress < 1 }
    private var isPast: Bool { progress >= 1 }
    private var isNext: Bool { segment.start.id == snapshot.next.id }
    private var isSunrise: Bool { segment.start.prayer == .sunrise }

    private var labelOpacity: Double {
        if isNext { return 1 }
        if isCurrent { return 0.8 }
        if isSunrise { return 0.3 }
        return isPast ? 0.35 : 0.5
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(isPast ? 0.72 : 0.14))
                    if isCurrent {
                        Capsule()
                            .fill(palette.accent)
                            .frame(width: max(2, geo.size.width * progress))
                        Circle()
                            .fill(palette.accent)
                            .frame(width: 5, height: 5)
                            .shadow(color: palette.accent.opacity(0.9), radius: 4)
                            .offset(x: max(0, geo.size.width * progress - 2.5))
                    }
                }
            }
            .frame(height: 2)

            VStack(alignment: .leading, spacing: 2) {
                Group {
                    if app.isArabic {
                        Text(app.strings.prayer(segment.start.prayer))
                            .font(app.display(10.5, weight: isNext ? .bold : .regular))
                    } else {
                        Text(app.strings.prayer(segment.start.prayer))
                            .font(.mono(8.5, weight: isNext ? .semibold : .medium))
                            .tracking(1.2)
                            .textCase(.uppercase)
                    }
                }
                .foregroundStyle(isNext ? palette.accent : .white)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(app.formatTime(segment.start.time))
                        .font(app.display(13, weight: isNext ? .regular : .light))
                        .monospacedDigit()
                    if let p = app.formatPeriod(segment.start.time) {
                        Text(p).font(.mono(7)).opacity(0.6)
                    }
                }
                .foregroundStyle(.white)
            }
            .opacity(labelOpacity)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
