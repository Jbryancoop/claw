import Foundation
import CoreLocation
import UIKit

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var lastLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isUpdating: Bool = false
    @Published var lastUploadTime: Date?
    @Published var lastError: String?

    private let manager = CLLocationManager()
    private var lastSentLocation: CLLocation?
    private var lastSentTime: Date = .distantPast
    private var isInBackground: Bool = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = ServerConfig.locationDistanceFilter
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = true
        // Reduce power: activity type helps iOS optimize GPS usage
        manager.activityType = .other

        authorizationStatus = manager.authorizationStatus

        // Listen for app lifecycle to switch between GPS modes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    // MARK: - Public

    func requestPermission() {
        manager.requestAlwaysAuthorization()
    }

    func startUpdating() {
        guard authorizationStatus == .authorizedAlways ||
              authorizationStatus == .authorizedWhenInUse else {
            requestPermission()
            return
        }

        isUpdating = true

        if isInBackground && ServerConfig.useSignificantChangesInBackground {
            // Significant changes only: wakes app for ~500m moves via cell/Wi-Fi.
            // Uses virtually no additional battery.
            manager.stopUpdatingLocation()
            manager.startMonitoringSignificantLocationChanges()
        } else {
            manager.stopMonitoringSignificantLocationChanges()
            manager.startUpdatingLocation()
        }
    }

    func stopUpdating() {
        isUpdating = false
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
    }

    func sendLocationNow() {
        guard let location = lastLocation else { return }
        Task { await uploadLocation(location, force: true) }
    }

    // MARK: - Background/Foreground Switching

    @objc private func appDidEnterBackground() {
        isInBackground = true
        guard isUpdating else { return }

        if ServerConfig.useSignificantChangesInBackground {
            // Switch to low-power significant-change monitoring
            manager.stopUpdatingLocation()
            manager.startMonitoringSignificantLocationChanges()
            // Lower accuracy saves battery when we do get a reading
            manager.desiredAccuracy = kCLLocationAccuracyKilometer
        }
    }

    @objc private func appWillEnterForeground() {
        isInBackground = false
        guard isUpdating else { return }

        // Restore full-accuracy continuous updates
        manager.stopMonitoringSignificantLocationChanges()
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.startUpdatingLocation()
    }

    // MARK: - Upload

    private func uploadLocation(_ location: CLLocation, force: Bool = false) async {
        // Throttle: don't send more often than the configured interval
        let now = Date()
        if !force && now.timeIntervalSince(lastSentTime) < ServerConfig.foregroundUpdateInterval {
            return
        }

        // Skip if we haven't moved meaningfully since last upload
        if !force, let last = lastSentLocation,
           location.distance(from: last) < ServerConfig.locationDistanceFilter {
            return
        }

        let deviceLocation = DeviceLocation(from: location)
        do {
            let _: ServerResponse = try await APIClient.shared.postLocation(deviceLocation)
            lastSentLocation = location
            lastSentTime = now
            lastUploadTime = now
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.lastLocation = location
            if self.isUpdating {
                await self.uploadLocation(location)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedAlways ||
               manager.authorizationStatus == .authorizedWhenInUse {
                self.startUpdating()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.lastError = error.localizedDescription
        }
    }
}
