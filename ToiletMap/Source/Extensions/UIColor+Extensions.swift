//
//  UIColor+Extensions.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/02/18.
//

import Foundation
import UIKit

extension UIColor {
  convenience init(hex: String, alpha: CGFloat = 1.0) {
    var hex = hex
    if hex.first == "#" {
      hex = String(hex.dropFirst())
    }
    let v = Int(hex, radix: 16) ?? 0
    let r = CGFloat(v / Int(powf(256, 2)) % 256) / 255
    let g = CGFloat(v / Int(powf(256, 1)) % 256) / 255
    let b = CGFloat(v / Int(powf(256, 0)) % 256) / 255
    self.init(red: r, green: g, blue: b, alpha: min(max(alpha, 0), 1))
  }
}

extension UIColor {
  var hexString: String {
    let components = cgColor.components!
    let r: CGFloat = components[0]
    let g: CGFloat = components[1]
    let b: CGFloat = components[2]

    let hexString = String(
      format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)),
      lroundf(Float(b * 255)))
    return hexString
  }
}
