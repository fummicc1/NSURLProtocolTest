//
//  RealmInjector.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/08/02.
//

import Foundation
import RealmSwift

class RealmInjector {

  static let shared = RealmInjector()

  var realm: Realm

  private init() {
    // Migration
    let configuration = Realm.Configuration(
      schemaVersion: 4
    ) { migration, oldSchemaVersion in
      if oldSchemaVersion < 1 {
        return
      }
    }
    Realm.Configuration.defaultConfiguration = configuration

    self.realm = try! Realm()
  }

}
