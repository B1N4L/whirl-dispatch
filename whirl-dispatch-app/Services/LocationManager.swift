//
//  LocationManager.swift
//  whirl-dispatch-app
//
//  Created by Binal on 2026-10-25.
//

import Foundation
import CoreLocation
import Observation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    static let shared = LocationManager()

    var currentLocation: CLLocation? = nil
    var currentCoordinate: CLLocationCoordinate2D? = nil
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isLocationAuthorized: Bool = false
    var locationError: String? = nil

    // testing and plant room simulation
    var isSimulatedLocationActive: Bool = false
    var simulatedCoordinate: CLLocationCoordinate2D? = nil

    private let clManager: CLLocationManager

    override init() {
        self.clManager = CLLocationManager()
        super.init()

        self.clManager.delegate = self
        self.clManager.desiredAccuracy = kCLLocationAccuracyBest
        self.clManager.distanceFilter = 5.0
        self.authorizationStatus = clManager.authorizationStatus
        self.isLocationAuthorized = (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways)
    }


    // request authorization from technician
    func requestAuthorization() {
        clManager.requestWhenInUseAuthorization()
    }

    // start streaming location
    func startUpdating() {
        clManager.startUpdatingLocation()
    }

    // stop location updates
    func stopUpdating() {
        clManager.stopUpdatingLocation()
    }


    // effective coordinates (simulated or real GPS)
    var effectiveCoordinate: CLLocationCoordinate2D {
      if isSimulatedLocationActive, let sim = simulatedCoordinate {
          return sim
      }
      if let current = currentCoordinate {
          return current
      }
      // default fallback to regional central district if simulator location is off
      return CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
    }

    // simulate on-site arrival at a facility coordinate
    func simulateArrival(at coordinate: CLLocationCoordinate2D) {
        self.simulatedCoordinate = coordinate
        self.isSimulatedLocationActive = true
    }

    // reset simulation back to physical GPS
    func resetSimulation() {
        self.simulatedCoordinate = nil
        self.isSimulatedLocationActive = false
    }


    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            self.isLocationAuthorized = (manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways)
            if self.isLocationAuthorized {
                self.clManager.startUpdatingLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = latest
            self.currentCoordinate = latest.coordinate
            self.locationError = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error.localizedDescription
        }
    }
}
