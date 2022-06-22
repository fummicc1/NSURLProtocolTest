//
//  ShadowFloatyItem.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/07/26.
//

import Floaty
import Foundation

class ShadowFloatyItem: FloatyItem {
  override init() {
    super.init()

    buttonColor = AppColor.mainColor
    iconTintColor = AppColor.backgroundColor
    titleShadowColor = AppColor.shadowColor
    circleShadowColor = AppColor.shadowColor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
