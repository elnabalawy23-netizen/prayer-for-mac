import SwiftUI
import Adhan
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var updater: Updater
    @StateObject private var search = CitySearch()
    @State private var loginError: String?

    private var s: Strings { app.strings }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text(s.settings)
                    .font(app.display(32, weight: .light))
                    .foregroundStyle(.white)
                    .padding(.top, 8)

                section(s.location) { locationSection }
                section(s.calculation) { calculationSection }
                section(s.display) { displaySection }
                section(s.general) { generalSection }
                section(s.updates) { updatesSection }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .frame(width: 480, height: 760)
        .background(Palette.hex(0x0B0A0A))
        .preferredColorScheme(.dark)
        .environment(\.layoutDirection, app.isArabic ? .rightToLeft : .leftToRight)
    }

    // MARK: - Sections

    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).caption(9.5, opacity: 0.45)
            Hairline()
            content()
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("", selection: $app.settings.locationMode) {
                Text(s.useMyLocation).tag(LocationMode.automatic)
                Text(s.chooseCity).tag(LocationMode.manual)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if app.settings.locationMode == .automatic {
                if let loc = app.autoLocation { LocationRow(location: loc) }
                if app.isLocating {
                    Text(s.locating).caption()
                } else if let f = app.locationFailure {
                    Text(f == .denied ? s.locationDenied : s.locationFailed)
                        .font(app.display(12, weight: .regular))
                        .foregroundStyle(Palette.hex(0xFF9A66))
                    Button(s.useMyLocation) { app.refreshLocation() }.buttonStyle(.link)
                }
            } else {
                TextField(s.searchCity, text: $search.query)
                    .textFieldStyle(.plain)
                    .font(app.display(15, weight: .regular))
                    .padding(.vertical, 8)
                    .overlay(alignment: .bottom) { Hairline(opacity: 0.25) }

                if search.isSearching {
                    Text(s.searching).caption()
                } else if !search.query.isEmpty && search.results.isEmpty {
                    Text(s.noResults).caption()
                }

                ForEach(search.results.prefix(6)) { r in
                    Button {
                        Task {
                            if let place = await search.resolve(r) {
                                app.settings.manualLocation = place
                                search.query = ""
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(r.title).font(app.display(14, weight: .regular)).foregroundStyle(.white)
                            Text(r.subtitle).font(app.display(12, weight: .regular)).foregroundStyle(.white.opacity(0.45))
                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                if let loc = app.settings.manualLocation { LocationRow(location: loc) }
            }
        }
    }

    private var calculationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let autoMethod = app.location.map { MethodResolver.method(for: $0.countryCode) }
            row(s.method) {
                Picker("", selection: $app.settings.methodOverride) {
                    Text(autoMethod.map { "\(s.autoByCountry) · \(s.methodShort($0))" } ?? s.autoByCountry)
                        .tag(CalculationMethod?.none)
                    ForEach(CalculationMethod.allCases.filter { $0 != .other }, id: \.self) { m in
                        Text(s.method(m)).tag(CalculationMethod?.some(m))
                    }
                }
            }
            let autoMadhab = app.location.map { MethodResolver.madhab(for: $0.countryCode) }
            row(s.asrMadhab) {
                Picker("", selection: $app.settings.madhabOverride) {
                    Text(autoMadhab.map { "\(s.autoByCountry) · \(s.madhab($0))" } ?? s.autoByCountry)
                        .tag(Madhab?.none)
                    ForEach(Madhab.allCases, id: \.self) { m in
                        Text(s.madhab(m)).tag(Madhab?.some(m))
                    }
                }
            }
        }
    }

    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            row(s.timeFormat) {
                Picker("", selection: $app.settings.timeFormat) {
                    Text(s.systemDefault).tag(TimeFormat.system)
                    Text(s.twelveHour).tag(TimeFormat.twelveHour)
                    Text(s.twentyFourHour).tag(TimeFormat.twentyFourHour)
                }
            }
            row(s.language) {
                Picker("", selection: $app.settings.language) {
                    Text(s.systemDefault).tag(AppLanguage.system)
                    Text(s.arabic).tag(AppLanguage.arabic)
                    Text(s.english).tag(AppLanguage.english)
                }
            }
        }
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if NSScreen.builtInWithNotch != nil {
                row(s.showMenuBarIcon) {
                    Toggle("", isOn: $app.settings.showMenuBarIcon).toggleStyle(.switch).labelsHidden()
                }
            }
            row(s.launchAtLogin) {
                Toggle("", isOn: Binding(
                    get: { app.settings.launchAtLogin },
                    set: { on in
                        do {
                            try LoginItem.set(on)
                            app.settings.launchAtLogin = on
                            loginError = nil
                        } catch {
                            loginError = error.localizedDescription
                        }
                    }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }
            if let e = loginError {
                Text(e).font(app.display(11, weight: .regular)).foregroundStyle(Palette.hex(0xFF9A66))
            }
            Button(action: { NSApp.terminate(nil) }) {
                Text(s.quit)
                    .pillLabel()
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
    }

    private var updatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            row(s.checkForUpdates) {
                Picker("", selection: $app.settings.updateCheckDays) {
                    Text(s.daily).tag(1)
                    Text(s.weekly).tag(7)
                    Text(s.never).tag(0)
                }
            }
            row(s.autoInstallUpdates) {
                Toggle("", isOn: $app.settings.autoInstallUpdates).toggleStyle(.switch).labelsHidden()
            }
            HStack(spacing: 12) {
                Button(action: { Task { await updater.check(installIfFound: false) } }) {
                    Text(s.checkNow)
                        .pillLabel()
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(!updater.isBundled || updater.state == .checking)

                if case .available = updater.state {
                    Button(action: { Task { await updater.install() } }) {
                        Text(s.installUpdate)
                            .pillLabel()
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(.white))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.top, 4)

            Text(updateStatus)
                .font(app.display(12, weight: .regular))
                .foregroundStyle(.white.opacity(0.6))

            Text("\(s.version) \(updater.currentVersion)\(lastCheckedText)")
                .caption(9, opacity: 0.4)
                .padding(.top, 4)
        }
    }

    private var updateStatus: String {
        guard updater.isBundled else { return s.notBundled }
        switch updater.state {
        case .idle: return ""
        case .checking: return s.checking
        case .upToDate: return s.upToDate
        case .available(let v): return "\(s.updateAvailable): \(v)"
        case .downloading(let v): return "\(s.downloading) \(v)…"
        case .installing(let v): return "\(s.installing) \(v)…"
        case .failed(let why): return "\(s.updateFailed): \(why)"
        }
    }

    private var lastCheckedText: String {
        guard let d = updater.lastCheckedAt else { return "" }
        let f = DateFormatter()
        f.locale = Locale(identifier: app.isArabic ? "ar_EG@numbers=latn" : "en_US")
        f.dateStyle = .medium
        f.timeStyle = .short
        return "  ·  \(s.lastChecked): \(f.string(from: d))"
    }

    private func row<Content: View>(_ label: String, @ViewBuilder _ control: () -> Content) -> some View {
        HStack {
            Text(label).font(app.display(13, weight: .regular)).foregroundStyle(.white.opacity(0.85))
            Spacer()
            control().labelsHidden().frame(maxWidth: 250)
        }
    }
}

private struct LocationRow: View {
    @EnvironmentObject var app: AppState
    let location: PlaceLocation

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(location.displayName(arabic: app.isArabic)).font(app.display(22, weight: .light)).foregroundStyle(.white)
                Text(location.displayCountry(arabic: app.isArabic)).font(app.display(13, weight: .regular)).foregroundStyle(.white.opacity(0.5))
            }
            Text("\(location.timeZoneID)  ·  \(String(format: "%.3f, %.3f", location.latitude, location.longitude))")
                .caption(9, opacity: 0.4)
        }
        .padding(.top, 2)
    }
}

enum LoginItem {
    static func set(_ enabled: Bool) throws {
        if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
    }
}
