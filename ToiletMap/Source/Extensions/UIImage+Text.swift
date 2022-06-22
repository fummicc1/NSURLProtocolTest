//
//  UIImage+Text.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/11/29.
//

import Foundation
import UIKit

extension UIImage {
  func generateText(lineHeight: CGFloat) -> String {
    let attachment = NSTextAttachment()
    attachment.image = self
    attachment.bounds = CGRect(
      x: 0, y: -5, width: size.width / size.height * lineHeight, height: lineHeight)
    let imageAttributeString = NSAttributedString(attachment: attachment)
    return imageAttributeString.string
  }
}
