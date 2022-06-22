import CoreLocation
import EasyFirebaseSwiftFirestore
import FirebaseFirestore
import FirebaseFirestoreSwift
import StubKit
//
//  Toilet.swift
//  NewToiletCritic
//
//  Created by 田中郁弥 on 2018/04/27.
//  Copyright © 2018年 fumiya. All rights reserved.
//
import UIKit

protocol ToiletType {
  var sender: String? { get }
  var name: String? { get }
  var detail: String? { get }
  var latitude: Double { get }
  var longitude: Double { get }
  var ref: DocumentReference? { get }
  var createdAt: Timestamp? { get }
  var updatedAt: Timestamp? { get }
}

enum Entity {

  struct ArchivedToilet: FirestoreModel, SubCollectionModel, ToiletType {
    var origin: DocumentReference?
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
    var memo: String?

    static var collectionName: String = FirestoreCollcetionName.archivedToilets.rawValue
    static var singleIdentifier: String = collectionName
    static var arrayIdentifier: String = collectionName + "_array"
    static var parentModelType: FirestoreModel.Type = User.self

    enum CodingKeys: String, CodingKey {
      case origin
      case sender
      case name
      case detail
      case latitude
      case longitude
      case ref
      case memo
      case createdAt = "created_at"
      case updatedAt = "updated_at"
    }
  }

  struct Toilet: FirestoreModel, ToiletType {
    static var collectionName: String = FirestoreCollcetionName.toilets.rawValue
    static var singleIdentifier: String = collectionName
    static var arrayIdentifier: String = collectionName + "_array"

    var sender: String?
    var name: String?
    var detail: String?
    var latitude: Double
    var longitude: Double
    @DocumentID
    var ref: DocumentReference?
    @ServerTimestamp
    var createdAt: Timestamp?
    @ServerTimestamp
    var updatedAt: Timestamp?

    enum CodingKeys: String, CodingKey {
      case sender
      case name
      case detail
      case latitude
      case longitude
      case ref
      case createdAt = "created_at"
      case updatedAt = "updated_at"
    }
  }

  struct CreatedToilet: FirestoreModel, ToiletType {
    static var collectionName: String = FirestoreCollcetionName.toilets.rawValue
    static var singleIdentifier: String = collectionName
    static var arrayIdentifier: String = collectionName + "_created_" + "_array"

    var sender: String?
    var name: String?
    var detail: String?
    var latitude: Double
    var longitude: Double
    @DocumentID
    var ref: DocumentReference?
    @ServerTimestamp
    var createdAt: Timestamp?
    @ServerTimestamp
    var updatedAt: Timestamp?

    enum CodingKeys: String, CodingKey {
      case sender
      case name
      case detail
      case latitude
      case longitude
      case ref
      case createdAt = "created_at"
      case updatedAt = "updated_at"
    }

    func convertToToilet() -> Entity.Toilet {
      Entity.Toilet(
        sender: sender,
        name: name,
        detail: detail,
        latitude: latitude,
        longitude: longitude,
        ref: ref,
        createdAt: createdAt,
        updatedAt: updatedAt
      )
    }
  }
}

extension Entity.Toilet: Equatable {
  static func == (rhs: Entity.Toilet, lhs: Entity.Toilet) -> Bool {
    return rhs.latitude == lhs.latitude && rhs.longitude == lhs.longitude
  }
}

extension Entity.ArchivedToilet: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(latitude)
    hasher.combine(longitude)
    hasher.combine(createdAt)
    hasher.combine(updatedAt)
  }
}

extension Entity.Toilet: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(latitude)
    hasher.combine(longitude)
    hasher.combine(createdAt)
    hasher.combine(updatedAt)
  }
}
