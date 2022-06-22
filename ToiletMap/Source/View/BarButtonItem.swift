//
//  BarButtonItem.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/09/18.
//

import Foundation
import UIKit

class BarButtonItem: UIBarButtonItem {

  override init() {
    super.init()
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    tintColor = AppColor.backgroundColor
  }

}
