//
//  HomeToilet.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/04/17.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

extension Entity {
  struct HomeToilet: Codable, Hashable {
    var sender: String?
    var name: String?
    var detail: String?
    var latitude: Double
    var longitude: Double

    enum CodingKeys: String, CodingKey {
      case sender
      case name
      case detail
      case latitude
      case longitude
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(sender)
      hasher.combine(name)
      hasher.combine(detail)
      hasher.combine(latitude)
      hasher.combine(longitude)
    }
  }
}
