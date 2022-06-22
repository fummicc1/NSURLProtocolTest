//
//  ToiletMapAnnotation.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2019/10/26.
//

import FirebaseFirestore
import Foundation
import MapKit
import RxSwift

protocol MapAnnotation: MKAnnotation {
  var toilet: ToiletPresentable { get }
  var isArchived: Bool { get }
  var isHighlight: Bool { get set }
}

class LocationComparision {
  static func compare(lhs: MapAnnotation, rhs: MapAnnotation) -> Bool {
    lhs.coordinate.latitude == rhs.coordinate.latitude
      && lhs.coordinate.longitude == rhs.coordinate.longitude
  }
}

class ToiletMapAnnotation: NSObject, MapAnnotation {

  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: toilet.latitude, longitude: toilet.longitude)
  }

  var isHighlight: Bool

  var title: String? {
    return name
  }

  var detail: String {
    toilet.detail ?? ""
  }

  var subtitle: String? {
    toilet.detail
  }

  var name: String {
    toilet.name ?? ""
  }

  var isArchived: Bool

  let toilet: ToiletPresentable
  var distance: Double?

  init(toilet: ToiletPresentable, distance: Double? = nil, isHighlight: Bool = false) {
    self.toilet = toilet
    self.distance = distance
    isArchived = type(of: toilet) == ArchivedToiletFragment.self
    self.isHighlight = isHighlight
  }
}

class iOSMapAnnotation: NSObject, MapAnnotation {
  var coordinate: CLLocationCoordinate2D

  var isArchived: Bool = false

  var isHighlight: Bool

  var toilet: ToiletPresentable

  var country: String
  var state: String
  var name: String
  var locality: String

  var detail: String {
    subtitle ?? ""
  }
  var distance: Double?
  var placemark: MKPlacemark

  var title: String? {
    if let distance = distance {
      let distanceText = String(format: "%.f m", distance)
      return distanceText
    }
    return nil
  }

  var subtitle: String? {
    return "\(String(describing: name)). \(locality)"
  }

  let disposeBag: DisposeBag = DisposeBag()

  init(placemark: MKPlacemark, distance: Double? = nil, isHighlight: Bool = false) {

    let name = placemark.name ?? ""
    let locality = placemark.locality ?? ""
    let detail = "\(name). \(locality)"

    self.placemark = placemark
    self.country = placemark.country ?? ""
    self.state = placemark.administrativeArea ?? ""
    self.coordinate = placemark.coordinate
    self.name = name
    self.locality = locality
    self.distance = distance

    let toiletFragment = ToiletFragment(
      sender: nil,
      name: name,
      detail: detail,
      latitude: coordinate.latitude,
      longitude: coordinate.longitude,
      ref: nil,
      createdAt: nil,
      updatedAt: nil,
      isArchived: false
    )

    self.toilet = toiletFragment
    self.isHighlight = isHighlight

    super.init()
  }
}

class ToiletRouteStepAnnotation: NSObject, MKAnnotation {

  var coordinate: CLLocationCoordinate2D

  var distance: Double

  var stepIndex: Int

  var title: String?

  init(coordinate: CLLocationCoordinate2D, distance: Double, stepIndex: Int) {
    self.coordinate = coordinate
    self.distance = distance
    self.title = "曲がり角"
    self.stepIndex = stepIndex
  }
}

class HomeToiletAnnotation: ToiletMapAnnotation {

  init(toilet: HomeToiletPresentable, distance: Double?) {
    super.init(toilet: toilet, distance: distance, isHighlight: false)
  }
}
