//
//  SettingCollectionSignOutCell.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/07/15.
//

import Foundation
import UIKit

protocol SettingCollectionButtonCellType {
  var action: (() -> Void)? { get set }
}

class SettingCollectionSignOutCell: UICollectionViewCell, SettingCollectionButtonCellType {

  lazy var signOutButton: RadiusButton = RadiusButton(
    frame: .zero,
    borderWidth: 0,
    buttonTitle: "サインアウト",
    buttonImage: nil
  )

  var action: (() -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    signOutButton.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(signOutButton)
    signOutButton.addAction(
      UIAction(handler: { _ in
        UIImpactFeedbackGenerator().impactOccurred()
        self.action?()
      }), for: .touchUpInside)

    // Design
    signOutButton.layer.cornerRadius = 8
    signOutButton.backgroundColor = AppColor.mainColor
    signOutButton.setTitleColor(AppColor.backgroundColor, for: .normal)
    signOutButton.contentEdgeInsets = .init(top: 8, left: 16, bottom: 8, right: 16)
    signOutButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)

    signOutButton.snp.makeConstraints { maker in
      maker.center.equalToSuperview()
      maker.top.equalToSuperview().offset(16)
      maker.height.equalTo(44)
      maker.height.equalTo(120)
    }

    signOutButton.setTitleColor(AppColor.accentColor, for: .highlighted)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
