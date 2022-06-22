//
//  LocalToiletDiary.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/07/31.
//

import Foundation
import RealmSwift
import RxRealm
import RxRelay
import RxSwift

enum ToiletDiaryType: String, Codable {
  case pee
  case poop
  case peeAndPoop
  case other
}

extension ToiletDiaryType {
  var message: String {
    switch self {
    case .pee:
      return "おしっこ"
    case .poop:
      return "うんち"
    case .peeAndPoop:
      return "おしっこ&うんち"
    case .other:
      return ""
    }
  }

  var imageName: String {
    switch self {
    case .pee:
      return "pee_fill"

    case .poop:
      return "poop_fill"

    case .peeAndPoop:
      return "pee_poop_fill"

    case .other:
      return ""
    }
  }
}

class LocalToiletDiary: Object {
  @objc dynamic var id: String = UUID().uuidString
  @objc dynamic var toiletDiaryType: String = "pee"
  @objc dynamic var date: Date = Date()
  @objc dynamic var memo: String = ""
  @objc dynamic var latitude: Double = 0
  @objc dynamic var longitude: Double = 0
  @objc dynamic var toiletID: String? = nil

  override class func primaryKey() -> String? {
    "id"
  }
}

extension LocalToiletDiary {

  static func create(entity: LocalToiletDiary) -> Disposable {

    let realm = RealmInjector.shared.realm

    return Observable.from(object: entity).subscribe(realm.rx.add())
  }

  func update<T>(keyPath: WritableKeyPath<LocalToiletDiary, T>, value: T) throws {
    let realm = RealmInjector.shared.realm

    var data = self

    try realm.write {
      data[keyPath: keyPath] = value
    }
  }

  func delete() throws {
    let realm = RealmInjector.shared.realm
    try realm.write {
      realm.delete(self)
    }
  }
}
