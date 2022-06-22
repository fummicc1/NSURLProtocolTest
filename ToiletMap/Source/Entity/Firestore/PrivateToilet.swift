//
//  PrivateToilet.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/04/01.
//

import EasyFirebaseSwiftFirestore
import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

extension Entity {
  struct PrivateToilet: FirestoreModel, SubCollectionModel, ToiletType {
    static var singleIdentifier: String = collectionName

    static var arrayIdentifier: String = "\(singleIdentifier)s"

    static var collectionName: String = FirestoreCollcetionName.privateToilet.rawValue

    @DocumentID
    var ref: DocumentReference?

    @ServerTimestamp
    var createdAt: Timestamp?

    @ServerTimestamp
    var updatedAt: Timestamp?

    var sender: String?

    var name: String?

    var detail: String?

    var latitude: Double

    var longitude: Double

    static var parentModelType: FirestoreModel.Type = User.self

    enum CodingKeys: String, CodingKey {
      case ref
      case createdAt = "created_at"
      case updatedAt = "updated_at"
      case sender
      case name
      case detail
      case latitude
      case longitude
    }
  }
}
