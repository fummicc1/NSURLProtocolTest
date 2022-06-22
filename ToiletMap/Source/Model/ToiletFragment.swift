//
//  ToiletFragment.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/18.
//

import CoreLocation
import FirebaseFirestore
import Foundation

protocol ToiletPresentable {
  var sender: UserPresentable? { get }
  var name: String? { get }
  var detail: String? { get }
  var latitude: Double { get }
  var longitude: Double { get }
  var ref: DocumentReference? { get set }
  var createdAt: Date? { get }
  var updatedAt: Date? { get }
  var isArchived: Bool { get }

  var coordinate: CLLocationCoordinate2D { get }
}

struct ToiletFragment: ToiletPresentable, Hashable {
  var sender: UserPresentable?

  var name: String?

  var detail: String?

  var latitude: Double

  var longitude: Double

  var ref: DocumentReference?

  var createdAt: Date?

  var updatedAt: Date?

  var isArchived: Bool

  var coordinate: CLLocationCoordinate2D {
    .init(latitude: latitude, longitude: longitude)
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(ref)
    hasher.combine(coordinate.latitude)
    hasher.combine(coordinate.longitude)
  }

  static func == (lhs: ToiletFragment, rhs: ToiletFragment) -> Bool {
    lhs.ref == rhs.ref && lhs.coordinate == rhs.coordinate
  }
}
