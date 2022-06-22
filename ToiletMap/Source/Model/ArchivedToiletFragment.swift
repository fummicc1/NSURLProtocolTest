//
//  ArchivedToiletFragment.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/19.
//

import CoreLocation
import FirebaseFirestore
import Foundation

protocol ArchivedToiletPresentable: ToiletPresentable {
  var toiletRef: DocumentReference? { get }
}

struct ArchivedToiletFragment: ArchivedToiletPresentable, ToiletPresentable, Hashable {
  var toiletRef: DocumentReference?

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
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.ref == rhs.ref
  }
}
