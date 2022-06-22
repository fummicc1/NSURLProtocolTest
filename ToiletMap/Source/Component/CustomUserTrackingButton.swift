//
//  CustomUserTrackingButton.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/05/26.
//

import Foundation
import MapKit

class CustomUserTrackingButton: MKUserTrackingButton {
  override var intrinsicContentSize: CGSize {
    let origin = super.intrinsicContentSize
    return .init(width: origin.width + 8, height: origin.height + 8)
  }
}
