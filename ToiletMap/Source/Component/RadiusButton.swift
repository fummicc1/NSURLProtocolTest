//
//  BorderView.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/09.
//

import Foundation
import UIKit

class RadiusButton: UIButton {

  private let contentSizeOffset: UIEdgeInsets = .init(top: 0, left: 4, bottom: 0, right: 4)

  @IBInspectable var borderWidth: CGFloat {
    get {
      self.layer.borderWidth
    }
    set {
      self.layer.borderWidth = newValue
    }
  }

  @IBInspectable var cornerRadius: CGFloat {
    get {
      self.layer.cornerRadius
    }
    set {
      self.layer.cornerRadius = newValue
    }
  }

  init(
    frame: CGRect, cornerRadius: CGFloat = 4, borderWidth: CGFloat, buttonTitle: String?,
    buttonImage: UIImage?
  ) {
    super.init(frame: frame)
    tintColor = AppColor.mainColor
    layer.borderColor = AppColor.mainColor.cgColor
    layer.borderWidth = borderWidth
    layer.cornerRadius = cornerRadius
    setTitle(buttonTitle, for: .normal)
    setTitleColor(AppColor.mainColor, for: .normal)
    setImage(buttonImage, for: .normal)
    adjustsImageSizeForAccessibilityContentSizeCategory = true
    titleLabel?.adjustsFontForContentSizeCategory = true
    imageView?.adjustsImageSizeForAccessibilityContentSizeCategory = true

    setTitleColor(AppColor.accentColor, for: .highlighted)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    layer.borderColor = tintColor.cgColor
    adjustsImageSizeForAccessibilityContentSizeCategory = true
    titleLabel?.adjustsFontForContentSizeCategory = true
    imageView?.adjustsImageSizeForAccessibilityContentSizeCategory = true
  }

  override var isHighlighted: Bool {
    didSet {

      if isHighlighted == oldValue {
        return
      }

      let base = self.contentEdgeInsets

      UIView.animate(withDuration: 0.3) {

        if self.isHighlighted {

          self.contentEdgeInsets = .init(
            top: base.top - self.contentSizeOffset.top,
            left: base.left - self.contentSizeOffset.left,
            bottom: base.bottom - self.contentSizeOffset.bottom,
            right: base.right - self.contentSizeOffset.right
          )

        } else {

          self.contentEdgeInsets = .init(
            top: base.top + self.contentSizeOffset.top,
            left: base.left + self.contentSizeOffset.left,
            bottom: base.bottom + self.contentSizeOffset.bottom,
            right: base.right + self.contentSizeOffset.right
          )

        }

        self.layoutIfNeeded()
      }
    }
  }

}
