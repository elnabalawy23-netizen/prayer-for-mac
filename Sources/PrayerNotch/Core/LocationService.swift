import Foundation
import CoreLocation

/// Resolves the Mac's current position into a PlaceLocation (city, country, time zone).
final class LocationService: NSObject, CLLocationManagerDelegate {
    enum Failure { case denied, failed }

    var onLocation: ((PlaceLocation) -> Void)?
    var onFailure: ((Failure) -> Void)?

    private let manager = CLLocationManager()
    private var wantsLocation = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func request() {
        wantsLocation = true
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            wantsLocation = false
            onFailure?(.denied)
        default:
            manager.requestLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard wantsLocation else { return }
        switch manager.authorizationStatus {
        case .notDetermined:
            break
        case .denied, .restricted:
            wantsLocation = false
            onFailure?(.denied)
        default:
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard wantsLocation, let loc = locations.last else { return }
        wantsLocation = false
        CLGeocoder().reverseGeocodeLocation(loc) { [weak self] placemarks, _ in
            let p = placemarks?.first
            let name = p?.locality ?? p?.subAdministrativeArea ?? p?.administrativeArea ?? p?.name ?? "—"
            var place = PlaceLocation(
                name: name,
                country: p?.country ?? "",
                countryCode: p?.isoCountryCode ?? "",
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                timeZoneID: (p?.timeZone ?? TimeZone.current).identifier
            )
            Task {
                place.names = await PlaceNames.lookup(latitude: place.latitude, longitude: place.longitude)
                await MainActor.run { self?.onLocation?(place) }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard wantsLocation else { return }
        wantsLocation = false
        let code = (error as? CLError)?.code
        DispatchQueue.main.async { [weak self] in
            self?.onFailure?(code == .denied ? .denied : .failed)
        }
    }
}
