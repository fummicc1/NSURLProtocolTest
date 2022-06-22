//
//  LocationShared.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/07.
//

import CoreLocation
import Foundation

class LocationShared {
  static let `default` = LocationShared()

  let locationManager = CLLocationManager()

  private init() {
    locationManager.startUpdatingHeading()
    locationManager.startUpdatingLocation()
  }

  func isValidAuthorization() -> Bool {
    locationManager.authorizationStatus == .authorizedAlways
      || locationManager.authorizationStatus == .authorizedWhenInUse
  }
}
