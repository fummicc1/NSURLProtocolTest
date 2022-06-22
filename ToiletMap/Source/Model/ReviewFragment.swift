//
//  ReviewFragment.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/18.
//

import FirebaseFirestore
import Foundation

protocol ReviewPresentable {
  var ref: DocumentReference? { get }
  var sender: UserPresentable { get }
  var canUse: Bool { get set }
  var isFree: Bool { get set }
  var hasWashlet: Bool { get set }
  var hasAccessibleRestroom: Bool { get set }
  var toilet: ToiletPresentable? { get }
  var createdAt: Date? { get }
  var updatedAt: Date? { get }
}

struct ReviewFragment: ReviewPresentable {
  var ref: DocumentReference?
  var sender: UserPresentable
  var canUse: Bool
  var isFree: Bool
  var hasWashlet: Bool
  var hasAccessibleRestroom: Bool
  var toilet: ToiletPresentable?
  var createdAt: Date?
  var updatedAt: Date?
}
