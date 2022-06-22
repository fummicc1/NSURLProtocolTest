//
//  UserDefaults.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/02/18.
//

import Foundation
import SwiftyUserDefaults
import UIKit

struct HexColor: Codable, DefaultsSerializable {
  let hexString: String

  static var _defaults: DefaultsHexColorBridge {
    DefaultsHexColorBridge()
  }

  static var _defaultsArray: DefaultsHexColorBridge {
    DefaultsHexColorBridge()
  }
}

struct DefaultsHexColorBridge: DefaultsBridge {

  typealias T = HexColor

  func get(key: String, userDefaults: UserDefaults) -> HexColor? {
    guard let hex = userDefaults.string(forKey: key) else {
      return nil
    }
    return HexColor(hexString: hex)
  }

  func save(key: String, value: HexColor?, userDefaults: UserDefaults) {
    guard let value = value else {
      return
    }
    userDefaults.set(value.hexString, forKey: key)
  }

  func deserialize(_ object: Any) -> HexColor? {
    if let hex = object as? String {
      return HexColor(hexString: hex)
    }
    return nil
  }
}

extension DefaultsKeys {
  var mainColor: DefaultsKey<HexColor> {
    DefaultsKey<HexColor>(
      "main_color",
      defaultValue: HexColor(
        hexString: AppColor.mainColor.hexString
      )
    )
  }
}
