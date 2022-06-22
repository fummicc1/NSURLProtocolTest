//
//  ErrorView.swift
//  BuSuc
//
//  Created by Fumiya Tanaka on 2021/01/07.
//

import Foundation
import SnapKit
import UIKit

class MessageView: XibView {

  @IBOutlet private weak var label: UILabel!
  @IBOutlet private weak var stackView: UIStackView!

  var text: String = "" {
    didSet {
      label.text = text
    }
  }
  var textColor: UIColor

  init(frame: CGRect, text: String, textColor: UIColor?) {
    self.textColor = textColor ?? AppColor.mainColor
    self.text = text
    super.init(frame: frame)
    label.text = text
    commonInit()
  }

  required init?(coder: NSCoder) {
    textColor = AppColor.mainColor
    super.init(coder: coder)
    commonInit()
  }

  override func commonInit() {
    super.commonInit()
    stackView.layer.cornerRadius = 8
    stackView.layer.masksToBounds = true

    label.textColor = textColor

    layer.masksToBounds = false
    layer.shadowColor = AppColor.mainColor.cgColor
    layer.shadowRadius = 8
    layer.shadowOffset = .init(width: 2, height: 2)
    layer.shadowOpacity = 0.2

  }

  @IBAction private func tap() {
    hide()
  }

  func hide() {
    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) { [weak self] in
      guard let self = self else {
        return
      }
      self.snp.updateConstraints { make in
        make.height.equalTo(0)
      }
      self.superview?.layoutIfNeeded()
    }
  }
}
