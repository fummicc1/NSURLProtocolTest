//
//  PlaceholderTextView.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/02/23.
//

import Foundation
import RxRelay
import RxSwift
import UIKit

class PlaceholderTextView: UITextView {

  let placeholderLabel: UILabel = .init()
  let disposeBag: DisposeBag = .init()

  var placeholderText: String = "プレイスホルダー" {
    didSet {
      placeholderLabel.text = placeholderText
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    let toolBar = UIToolbar()
    let spacer = UIBarButtonItem.flexibleSpace()
    let action = UIAction { _ in
      self.resignFirstResponder()
    }
    let closeButton = BarButtonItem(systemItem: .close, primaryAction: action)
    toolBar.items = [spacer, closeButton]
    toolBar.sizeToFit()

    inputAccessoryView = toolBar

    rx.text.orEmpty
      .filter({ $0.isEmpty })
      .subscribe(onNext: { [weak self] text in
        guard let self = self else {
          return
        }
        self.placeholderLabel.text = self.placeholderText
        self.placeholderLabel.sizeToFit()
      })
      .disposed(by: disposeBag)

    rx.text.orEmpty
      .map({ $0.isNotEmpty })
      .bind(to: placeholderLabel.rx.isHidden)
      .disposed(by: disposeBag)

    addSubview(placeholderLabel)

    placeholderLabel.snp.makeConstraints({ maker in
      maker.leading.equalToSuperview().offset(6)
      maker.top.equalToSuperview().offset(12)
    })
    placeholderLabel.textColor = AppColor.placeholderTextColor
    placeholderLabel.text = placeholderText
    placeholderLabel.sizeToFit()
  }

  func configure(placeholder: String) {
    placeholderText = placeholder
    placeholderLabel.sizeToFit()
  }
}
