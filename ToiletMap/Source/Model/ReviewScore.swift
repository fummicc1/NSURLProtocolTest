//
//  ReviewScore.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/07.
//

import Foundation

struct ReviewScore {
  let canUse: Double
  let isFree: Double
  let hasWashlet: Double
  let hasAccessibleRestroom: Double
  let alreadyReviewed: Bool
}

extension ReviewScore {
  func mapToValue(keypath: KeyPath<ReviewScore, Double>) -> ReviewValue {
    ReviewValue(yes: canUse, no: 1 - canUse)
  }
}
