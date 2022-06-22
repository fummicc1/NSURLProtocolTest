//
//  ToiletDiary.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2022/04/24.
//

import EasyFirebaseSwiftFirestore
import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

extension Entity {
  struct ToiletDiary: FirestoreModel {
    static var collectionName: String = FirestoreCollcetionName.toiletDiaries.rawValue

    @DocumentID
    var ref: DocumentReference?

    @ServerTimestamp
    var createdAt: Timestamp?

    @ServerTimestamp
    var updatedAt: Timestamp?

    var toiletDiaryType: String
    var date: Date
    var memo: String
    var latitude: Double
    var longitude: Double

    var sharedUsers: [String]

    enum CodingKeys: String, CodingKey {
      case toiletDiaryType = "toilet_diary_type"
      case date
      case memo
      case latitude
      case longitude
      case sharedUsers = "shared_users"
      case ref
      case createdAt = "created_at"
      case updatedAt = "updated_at"
    }
  }

}
