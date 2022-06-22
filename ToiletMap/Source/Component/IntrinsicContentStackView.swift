//
//  IntrinsicContentStackView.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/02/23.
//

import Foundation
import UIKit

class IntrinsicContentStackView: UIStackView {

  override var intrinsicContentSize: CGSize {
    let size =
      arrangedSubviews
      .filter({ $0.isHidden == false })
      .map(\.intrinsicContentSize)
      .reduce(.zero) { (total, size) in
        return CGSize(
          width: total.width + size.width,
          height: total.height + size.height
        )
      }
    return size
  }
}
