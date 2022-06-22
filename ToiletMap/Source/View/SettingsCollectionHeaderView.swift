//
//  SettingsCollectionHeaderView.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/02/18.
//

import Foundation
import UIKit

class SettingsCollectionHeaderView: UICollectionReusableView {

  func addText(_ text: String) {
    let label = UILabel()
    label.numberOfLines = 0
    label.text = text
    label.textColor = UIColor.secondaryLabel
    label.font = UIFont.preferredFont(forTextStyle: .caption1)
    label.sizeToFit()
    addSubview(label)
    label.snp.makeConstraints { (maker) in
      maker.top.leading.equalToSuperview().offset(8)
      maker.bottom.trailing.equalToSuperview().offset(-8)
    }
  }
}
