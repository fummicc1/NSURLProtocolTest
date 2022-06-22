//
//  Review.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/06.
//

import EasyFirebaseSwiftFirestore
import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

extension Entity {
  struct Review: FirestoreModel, SubCollectionModel, Equatable {

    static var collectionName: String = FirestoreCollcetionName.reviews.rawValue
    static var parentModelType: FirestoreModel.Type = Toilet.self
    static var singleIdentifier: String = collectionName
    static var arrayIdentifier: String = collectionName + "_array"

    let senderUID: String
    let canUse: Bool
    let isFree: Bool
    let hasWashlet: Bool
    let hasAccessibleRestroom: Bool
    @DocumentID
    var ref: DocumentReference?
    @ServerTimestamp
    var createdAt: Timestamp?
    @ServerTimestamp
    var updatedAt: Timestamp?

    var toilet: Entity.Toilet?

    enum CodingKeys: String, CodingKey {
      case senderUID = "sender_uid"
      case canUse = "can_use"
      case isFree = "is_free"
      case hasWashlet = "has_washlet"
      case hasAccessibleRestroom = "has_accessible_restroom"
      case ref
      case createdAt = "created_at"
      case updatedAt = "updated_at"
      case toilet
    }
  }
}
