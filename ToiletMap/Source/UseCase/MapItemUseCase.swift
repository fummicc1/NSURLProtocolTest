//
//  MapItemUseCase.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/19.
//

import Foundation
import MapKit
import RxRelay
import RxSwift

enum MapItemUseCase {

  struct SearchMapItemFromCurrentLocationUseCase {

    enum Error: Swift.Error {
      case noCurrentLocation
    }

    private let mapItemRepository: MapItemRepositoryType = MapItemRepository.shared
    private let locationShared = LocationShared.default

    func execute(word: String, radius: Double = 200) -> Single<[iOSMapAnnotation]> {

      guard let location = locationShared.locationManager.location else {
        return .error(Error.noCurrentLocation)
      }

      return mapItemRepository.search(
        with: word,
        center: location.coordinate,
        radius: radius
      )
      .map({ items in
        items.map({ item in
          let placeMark = item.placemark

          let distance = placeMark.coordinate.calculateDistance(with: location.coordinate)

          return iOSMapAnnotation(placemark: placeMark, distance: distance)
        })
      })
    }
  }

  struct SearchMapItemFromDataStore {
    enum Error: Swift.Error {
      case noCurrentLocation
    }

    private let mapItemRepository: MapItemRepositoryType = MapItemRepository.shared
    private let location = LocationShared.default

    func execute(word: String, limit: Int = 20) -> Observable<[ToiletMapAnnotation]> {
      guard let location = self.location.locationManager.location?.coordinate else {
        return .error(Self.Error.noCurrentLocation)
      }
      return
        mapItemRepository
        .search(with: word, central: location, limit: limit)
        .map({ toilets in
          toilets.map({ ToiletMapAnnotation(toilet: $0) })
        })
    }
  }

  struct ObserveCurrentMapItemUseCase {

    enum Error: Swift.Error {
      case noCurrentLocation
    }

    private let mapItemRepository: MapItemRepositoryType = MapItemRepository.shared
    private let locationShared = LocationShared.default

    func execute() -> Observable<[iOSMapAnnotation]> {

      guard let location = locationShared.locationManager.location else {
        return .error(Error.noCurrentLocation)
      }

      return mapItemRepository.searchedMapItems.map({ (items: [MKMapItem]) in
        items.map({ (item: MKMapItem) in
          iOSMapAnnotation(
            placemark: item.placemark,
            distance: item.placemark.coordinate.calculateDistance(with: location.coordinate)
          )
        })
      })
    }
  }
}
