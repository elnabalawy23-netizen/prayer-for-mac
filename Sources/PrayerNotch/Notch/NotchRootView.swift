import SwiftUI
import Adhan

struct NotchRootView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var ui: NotchUIState

    private var palette: Palette {
        guard let s = app.snapshot else { return .idle }
        return .forNext(s.next.prayer)
    }

    var body: some View {
        let expanded = ui.isExpanded
        let size = expanded ? NotchController.expandedSize : ui.collapsedSize
        let dx = expanded ? 0 : ui.collapsedOffsetX
        let shape = NotchShape(topRadius: expanded ? 10 : 6, bottomRadius: expanded ? 28 : 13)

        ZStack(alignment: .top) {
            shape.fill(Color.black)
            GlowLayer(palette: palette, expanded: expanded, size: size)
                .clipShape(shape)
            shape.strokeBorder(
                LinearGradient(colors: [.white.opacity(0.0), .white.opacity(expanded ? 0.10 : 0.05)],
                               startPoint: .top, endPoint: .bottom),
                lineWidth: 1
            )

            VStack(spacing: 0) {
                WingsRow(expanded: expanded, width: size.width, palette: palette)
                if expanded {
                    ExpandedBody(palette: palette)
                        .transition(.opacity.combined(with: .offset(y: -8)))
                }
            }
            .frame(width: size.width, height: size.height, alignment: .top)
            .clipShape(shape)
        }
        .frame(width: size.width, height: size.height)
        .contentShape(shape)
        .onTapGesture { ui.onTap?() }
        .environment(\.layoutDirection, app.isArabic ? .rightToLeft : .leftToRight)
        .offset(x: dx)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.46, dampingFraction: 0.84), value: expanded)
        .animation(.easeInOut(duration: 1.2), value: palette)
        .environment(\.layoutDirection, .leftToRight)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Glow

private struct GlowLayer: View {
    let palette: Palette
    let expanded: Bool
    let size: CGSize

    var body: some View {
        ZStack {
            Ellipse()
                .fill(RadialGradient(colors: [palette.glow.opacity(0.95), palette.glow.opacity(0)],
                                     center: .center, startRadius: 0, endRadius: 170))
                .frame(width: 380, height: 300)
                .offset(x: size.width * 0.30, y: size.height * (expanded ? 0.42 : 0.1))
                .blur(radius: 26)
            Ellipse()
                .fill(palette.deep)
                .frame(width: 320, height: 240)
                .offset(x: -size.width * 0.32, y: size.height * (expanded ? 0.62 : 0.2))
                .blur(radius: 48)
                .opacity(0.9)
        }
        .opacity(expanded ? 1 : 0.38)
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Wings (the strip beside the physical notch)

private struct WingsRow: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var ui: NotchUIState
    let expanded: Bool
    let width: CGFloat
    let palette: Palette

    private var isRTL: Bool { app.isArabic }
    private var expandedWing: CGFloat { (width - ui.notchSize.width) / 2 }
    private var leadingWing: CGFloat { expanded ? expandedWing : (isRTL ? ui.rightWingWidth : ui.leftWingWidth) }
    private var trailingWing: CGFloat { expanded ? expandedWing : (isRTL ? ui.leftWingWidth : ui.rightWingWidth) }

    var body: some View {
        HStack(spacing: 0) {
            leading
                .measured(expanded: expanded, slot: \.leading)
                .frame(width: leadingWing, height: ui.notchSize.height, alignment: expanded ? .leading : .center)
            Color.clear.frame(width: ui.notchSize.width, height: ui.notchSize.height)
            trailing
                .measured(expanded: expanded, slot: \.trailing)
                .frame(width: trailingWing, height: ui.notchSize.height, alignment: expanded ? .trailing : .center)
        }
        .frame(width: width, height: ui.notchSize.height)
        .onPreferenceChange(WingContentWidthKey.self) { widths in
            guard !expanded, widths.leading > 0, widths.trailing > 0 else { return }
            let margin = NotchUIState.wingMargin * 2
            let lead = max(NotchUIState.minWingWidth, (widths.leading + margin).rounded())
            let trail = max(NotchUIState.minWingWidth, (widths.trailing + margin).rounded())
            let (left, right) = isRTL ? (trail, lead) : (lead, trail)
            if abs(left - ui.leftWingWidth) > 0.5 { ui.leftWingWidth = left }
            if abs(right - ui.rightWingWidth) > 0.5 { ui.rightWingWidth = right }
            NSLog("[notch] wings left=%.0f right=%.0f", left, right)
        }
    }

    @ViewBuilder private var leading: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(palette.accent)
                .frame(width: 5, height: 5)
                .shadow(color: palette.accent.opacity(0.9), radius: 4)
            if let s = app.snapshot {
                if expanded {
                    Text(app.strings.nextPrayer).caption(9, opacity: 0.5)
                } else {
                    Text(app.strings.prayer(s.next.prayer))
                        .font(app.display(13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.92))
                }
            } else {
                Text(app.isLocating ? app.strings.locating : app.strings.noLocationShort)
                    .font(app.display(11.5, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .lineLimit(1)
        .padding(.leading, expanded ? 24 : 0)
    }

    @ViewBuilder private var trailing: some View {
        HStack(spacing: 10) {
            if let s = app.snapshot {
                Text(expanded ? app.countdown(s.remaining(at: app.now)) : app.countdownShort(s.remaining(at: app.now)))
                    .font(.mono(12, weight: .regular))
                    .foregroundStyle(.white.opacity(expanded ? 0.85 : 0.75))
                    .monospacedDigit()
            }
            if expanded {
                Button(action: { app.openSettings?() }) {
                    Text("···")
                        .font(.mono(12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .buttonStyle(.plain)
            }
        }
        .lineLimit(1)
        .padding(.trailing, expanded ? 22 : 0)
    }
}

// MARK: - Expanded body

private struct ExpandedBody: View {
    @EnvironmentObject var app: AppState
    let palette: Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let s = app.snapshot {
                HStack(alignment: .firstTextBaseline) {
                    Text(app.strings.prayer(s.next.prayer))
                        .font(app.display(44, weight: .light))
                        .tracking(-0.6)
                        .foregroundStyle(.white)
                    Spacer(minLength: 12)
                    VStack(alignment: .trailing, spacing: 3) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(app.formatTime(s.next.time))
                                .font(app.display(24, weight: .light))
                                .foregroundStyle(.white.opacity(0.95))
                            if let p = app.formatPeriod(s.next.time) {
                                Text(p).caption(9, opacity: 0.6)
                            }
                        }
                        Text(app.relative(s.remaining(at: app.now))).caption(9.5, opacity: 0.5)
                    }
                }
                .padding(.top, 4)

                HStack(spacing: 0) {
                    Text(s.location.displayName(arabic: app.isArabic))
                    Text("  ·  ")
                    Text(app.strings.methodShort(s.method))
                    Text("  ·  ")
                    Text(app.formatDate(app.now))
                }
                .caption(9.5, opacity: 0.45)
                .padding(.top, 6)

                TimelineView(snapshot: s, palette: palette)
                    .padding(.top, 20)
            } else {
                EmptyLocationView()
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 18)
    }
}

private struct EmptyLocationView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(app.strings.noLocation)
                .font(app.display(30, weight: .light))
                .foregroundStyle(.white)
            if app.isLocating {
                Text(app.strings.locating).caption()
            } else if let f = app.locationFailure {
                Text(f == .denied ? app.strings.locationDenied : app.strings.locationFailed).caption(9.5, opacity: 0.6)
            }
            Button(action: { app.openSettings?() }) {
                Text(app.strings.openSettings)
                    .pillLabel()
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(.white))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding(.top, 10)
    }
}

// MARK: - Wing content measurement

private struct WingWidths: Equatable {
    var leading: CGFloat = 0
    var trailing: CGFloat = 0
}

private struct WingContentWidthKey: PreferenceKey {
    static var defaultValue = WingWidths()
    static func reduce(value: inout WingWidths, nextValue: () -> WingWidths) {
        let n = nextValue()
        value.leading = max(value.leading, n.leading)
        value.trailing = max(value.trailing, n.trailing)
    }
}

private extension View {
    /// Reports the natural width of collapsed wing content so each wing can size itself to it.
    func measured(expanded: Bool, slot: WritableKeyPath<WingWidths, CGFloat>) -> some View {
        self.fixedSize()
            .background(GeometryReader { g in
                Color.clear.preference(key: WingContentWidthKey.self, value: {
                    var w = WingWidths()
                    w[keyPath: slot] = expanded ? 0 : g.size.width
                    return w
                }())
            })
    }
}
