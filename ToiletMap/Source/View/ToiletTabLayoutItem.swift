//
//  ToiletTabLayoutItem.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/17.
//

import Foundation
import UIKit

class ToiletTabLayoutItem: UIView {
  let index: Int
  let button: UIButton
  let indicator: UIView

  init(index: Int, text: String) {
    self.index = index
    indicator = UIView()
    button = UIButton()
    super.init(frame: .zero)

    indicator.backgroundColor = AppColor.mainColor

    button.setTitleColor(AppColor.placeholderTextColor, for: .normal)
    button.setTitle(text, for: .normal)
    button.titleLabel?.textAlignment = .center
    button.titleLabel?.adjustsFontSizeToFitWidth = true
    button.titleLabel?.minimumScaleFactor = 0.7
    button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
    button.titleLabel?.adjustsFontForContentSizeCategory = true

    addSubview(button)
    addSubview(indicator)

    button.snp.makeConstraints { (constraint) in
      constraint.leading.equalToSuperview().offset(16)
      constraint.trailing.equalToSuperview().offset(-16)
      constraint.top.equalToSuperview().offset(8)
      constraint.bottom.equalTo(indicator).offset(-8)
    }

    indicator.snp.makeConstraints { (constraint) in
      constraint.height.equalTo(2)
      constraint.leading.trailing.bottom.equalToSuperview()
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func updateState(isSelected: Bool) {
    button.setTitleColor(
      isSelected ? AppColor.textColor : AppColor.placeholderTextColor, for: .normal)

    indicator.snp.updateConstraints { (constraint) in
      constraint.height.equalTo(isSelected ? 2 : 0)
    }
  }

  func handleSelect(handler: @escaping (Int) -> Void) {
    button.addAction(
      UIAction(handler: { _ in
        handler(self.index)
      }), for: .touchUpInside)
  }
}
