//
//  RecentlyToilet.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/17.
//

import EasyFirebaseSwiftFirestore
import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct RecentlyToilet: FirestoreModel, SubCollectionModel {
  static var singleIdentifier: String = collectionName

  static var arrayIdentifier: String = collectionName + "_array"

  static var collectionName: String = FirestoreCollcetionName.recentlyToilets.rawValue

  @DocumentID
  var ref: DocumentReference?

  @ServerTimestamp
  var createdAt: Timestamp?

  @ServerTimestamp
  var updatedAt: Timestamp?

  @ServerTimestamp
  var sawAt: Timestamp?

  var sender: String?
  var name: String?
  var detail: String?
  var latitude: Double
  var longitude: Double
  var memo: String?

  static var parentModelType: FirestoreModel.Type = Entity.User.self
}
