//
//  UIImage+Resizable.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2019/10/26.
//

import Foundation
import UIKit

extension UIImage {
  func resize(in rect: CGRect, after size: CGSize) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
    draw(in: CGRect(origin: rect.origin, size: size))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return resizedImage
  }

  // image with rounded corners
  public func withRoundedCorners(radius: CGFloat? = nil) -> UIImage? {
    let maxRadius = min(size.width, size.height) / 2
    let cornerRadius: CGFloat
    if let radius = radius, radius > 0 && radius <= maxRadius {
      cornerRadius = radius
    } else {
      cornerRadius = maxRadius
    }
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    let rect = CGRect(origin: .zero, size: size)
    UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
    draw(in: rect)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
  }
}
