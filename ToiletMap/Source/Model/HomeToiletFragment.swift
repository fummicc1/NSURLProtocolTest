//
//  HomeToiletFragment.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/04/17.
//

import CoreLocation
import FirebaseFirestore
import Foundation

protocol HomeToiletPresentable: ToiletPresentable {
}

struct HomeToiletFragment: HomeToiletPresentable {
  var sender: UserPresentable?

  var name: String?

  var detail: String?

  var latitude: Double

  var longitude: Double

  var ref: DocumentReference? = nil

  var createdAt: Date?

  var updatedAt: Date?

  let isArchived: Bool = false

  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(
      latitude: latitude,
      longitude: longitude
    )
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(sender?.uid)
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.sender?.uid == rhs.sender?.uid
  }
}
