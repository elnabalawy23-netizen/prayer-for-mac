import Foundation
import MapKit

struct CityResult: Identifiable, Hashable {
    let completion: MKLocalSearchCompletion
    var id: String { completion.title + "|" + completion.subtitle }
    var title: String { completion.title }
    var subtitle: String { completion.subtitle }

    static func == (a: CityResult, b: CityResult) -> Bool { a.id == b.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Type-ahead city search backed by Apple Maps; resolves to exact coordinates + time zone.
@MainActor
final class CitySearch: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var query = "" {
        didSet {
            let q = query.trimmingCharacters(in: .whitespaces)
            if q.isEmpty { results = []; isSearching = false; return }
            isSearching = true
            completer.queryFragment = q
        }
    }
    @Published private(set) var results: [CityResult] = []
    @Published private(set) var isSearching = false
    @Published private(set) var isResolving = false

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let found = completer.results
        Task { @MainActor in
            self.results = found.filter(Self.looksLikeCity).map(CityResult.init)
            self.isSearching = false
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.results = []
            self.isSearching = false
        }
    }

    /// Street addresses contain digits or many comma parts; cities read like "Riyadh" / "Saudi Arabia".
    private static func looksLikeCity(_ c: MKLocalSearchCompletion) -> Bool {
        guard !c.title.contains(where: \.isNumber) else { return false }
        return c.title.split(separator: ",").count <= 2
    }

    func resolve(_ result: CityResult) async -> PlaceLocation? {
        isResolving = true
        defer { isResolving = false }
        let search = MKLocalSearch(request: MKLocalSearch.Request(completion: result.completion))
        guard let response = try? await search.start(), let item = response.mapItems.first else { return nil }
        let pm = item.placemark
        let coord = pm.coordinate
        let tz = item.timeZone ?? pm.timeZone ?? TimeZone.current
        let name = pm.locality ?? result.title.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? result.title
        var place = PlaceLocation(
            name: name,
            country: pm.country ?? result.subtitle,
            countryCode: pm.isoCountryCode ?? "",
            latitude: coord.latitude,
            longitude: coord.longitude,
            timeZoneID: tz.identifier
        )
        place.names = await PlaceNames.lookup(latitude: coord.latitude, longitude: coord.longitude)
        return place
    }
}
