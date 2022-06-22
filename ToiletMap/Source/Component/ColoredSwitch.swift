//
//  ColoredSwitch.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/07/26.
//

import Foundation
import UIKit

class ColoredSwitch: UISwitch {

  override init(frame: CGRect) {
    super.init(frame: frame)
    updateColor()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    updateColor()
  }

  private func updateColor() {
    onTintColor = AppColor.mainColor
    setNeedsDisplay()
  }
}
