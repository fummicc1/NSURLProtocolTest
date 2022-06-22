//
//  ToiletDiaryFragment.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/07/31.
//

import Foundation

protocol ToiletDiaryPresentable {
  var id: String { get }
  var date: Date { get }
  var memo: String { get }
  var type: ToiletDiaryType { get }
  var latitude: Double { get }
  var longitude: Double { get }
  var toilet: ToiletPresentable? { get }
}

struct ToiletDiaryFragment: ToiletDiaryPresentable, Hashable {

  var id: String

  var date: Date

  var memo: String

  var type: ToiletDiaryType

  var latitude: Double

  var longitude: Double

  var toilet: ToiletPresentable?

  init(
    id: String,
    date: Date,
    memo: String,
    type: ToiletDiaryType,
    latitude: Double,
    longitude: Double,
    toilet: ToiletPresentable?
  ) {
    self.id = id
    self.date = date
    self.memo = memo
    self.type = type
    self.latitude = latitude
    self.longitude = longitude
    self.toilet = toilet
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(date)
    hasher.combine(type)
    hasher.combine(memo)
    hasher.combine(latitude)
    hasher.combine(longitude)
  }
}
