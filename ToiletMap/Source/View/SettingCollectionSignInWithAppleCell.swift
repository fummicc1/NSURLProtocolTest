//
//  SettingCollectionSignInWithAppleCell.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/05/27.
//

import AuthenticationServices
import Foundation
import UIKit

class SettingCollectionSignInWithAppleCell: UICollectionViewCell, SettingCollectionButtonCellType {

  lazy var button: ASAuthorizationAppleIDButton = ASAuthorizationAppleIDButton(
    authorizationButtonType: .continue,
    authorizationButtonStyle: traitCollection.userInterfaceStyle == .dark ? .white : .black)

  var action: (() -> Void)?

  override func layoutSubviews() {
    super.layoutSubviews()
    button.frame = bounds
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.addSubview(button)
    button.addAction(
      UIAction(handler: { _ in
        self.action?()
      }), for: .touchUpInside)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
