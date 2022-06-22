//
//  RecentlyViewedToiletFragment.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/18.
//

import CoreLocation
import FirebaseFirestore
import Foundation

protocol RecentlyViewedToiletPresentable: ToiletPresentable {
  var sawAt: Date? { get }
}

struct RecentlyViewedToiletFragment: RecentlyViewedToiletPresentable, ToiletPresentable {
  var sender: UserPresentable?

  var createdAt: Date?

  var updatedAt: Date?

  var name: String?

  var detail: String?

  var latitude: Double

  var longitude: Double

  var ref: DocumentReference?

  var sawAt: Date?

  var isArchived: Bool

  var coordinate: CLLocationCoordinate2D {
    .init(latitude: latitude, longitude: longitude)
  }
}
