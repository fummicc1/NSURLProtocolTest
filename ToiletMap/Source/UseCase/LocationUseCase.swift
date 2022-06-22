//
//  LocationUseCase.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/18.
//

import CoreLocation
import Foundation
import MapKit
import RxCoreLocation
import RxRelay
import RxSwift

enum LocationUseCase {
}

protocol GetCurrentLocationUseCaseType {
  func execute() throws -> CLLocation?
}

extension LocationUseCase {
  struct GetCurrentLocationUseCase: GetCurrentLocationUseCaseType {

    enum Error: Swift.Error {
      case unauthorized
    }

    let locationShared = LocationShared.default

    func execute() throws -> CLLocation? {
      if self.locationShared.isValidAuthorization() == false {
        throw Error.unauthorized
      }
      let location = self.locationShared.locationManager.location
      return location
    }
  }

}

protocol RequestAuthorizationUseCaseType {
  func execute(isFullAccuracy: Bool, purposeKey: String?)
}

extension LocationUseCase {
  struct RequestAuthorizationUseCase: RequestAuthorizationUseCaseType {

    let locationShared = LocationShared.default

    func execute(isFullAccuracy: Bool, purposeKey: String?) {
      if isFullAccuracy, let purposeKey = purposeKey {
        locationShared.locationManager.requestTemporaryFullAccuracyAuthorization(
          withPurposeKey: purposeKey
        ) { (error) in
          if let error = error {
            assertionFailure(error.localizedDescription)
          }
        }
      } else {
        locationShared.locationManager.requestWhenInUseAuthorization()
      }
    }
  }
}

protocol ObserveCurrentLocationUseCaseType {
  func execute() -> Observable<CLLocation>
}

extension LocationUseCase {
  struct ObserveCurrentLocationUseCase: ObserveCurrentLocationUseCaseType {
    let locationShared = LocationShared.default

    func execute() -> Observable<CLLocation> {
      locationShared.locationManager.rx.location.compactMap({ $0 })
    }
  }

}

protocol AddRouteStepRegionType {
  func execute(
    routeStep routeStepCoordinate: CLLocationCoordinate2D,
    radius: Double,
    index: Int
  )
}

extension LocationUseCase {
  struct AddRouteStepRegion: AddRouteStepRegionType {
    let locationShared = LocationShared.default

    func execute(
      routeStep routeStepCoordinate: CLLocationCoordinate2D,
      radius: Double = 30,
      index: Int
    ) {
      let region = CLCircularRegion(
        center: routeStepCoordinate,
        radius: radius,
        identifier: String(index)
      )
      if locationShared.locationManager.monitoredRegions.contains(region) {
        locationShared.locationManager.stopMonitoring(for: region)
      }
      locationShared.locationManager.startMonitoring(for: region)
    }
  }
}

protocol ObserveAuthorizationStatusUseCaseType {
  func execute() -> Observable<CLAuthorizationStatus>
}

extension LocationUseCase {
  struct ObserveAuthorizationStatusUseCase: ObserveAuthorizationStatusUseCaseType {

    let locationShared = LocationShared.default

    func execute() -> Observable<CLAuthorizationStatus> {
      locationShared.locationManager.rx.didChangeAuthorization.map({ event in
        event.status
      })
    }

  }
}

protocol ObserveRouteStepRegionEnteredType {
  func execute() -> Observable<CLRegionEvent>
}

extension LocationUseCase {
  struct ObserveRouteStepRegionEntered: ObserveRouteStepRegionEnteredType {

    let locationShared = LocationShared.default

    func execute() -> Observable<CLRegionEvent> {
      locationShared.locationManager
        .rx.didReceiveRegion
        .filter({ $0.state == .enter })
    }
  }
}

protocol ObserveRouteStepRegionExitedType {
  func execute(index: Int) -> Observable<CLRegionEvent>
}

extension LocationUseCase {
  struct ObserveRouteStepRegionExited: ObserveRouteStepRegionExitedType {
    let locationShared = LocationShared.default

    func execute(index: Int) -> Observable<CLRegionEvent> {
      locationShared.locationManager.rx.didReceiveRegion.filter({
        $0.state == .exit && $0.region.identifier == String(index)
      })
    }
  }
}
