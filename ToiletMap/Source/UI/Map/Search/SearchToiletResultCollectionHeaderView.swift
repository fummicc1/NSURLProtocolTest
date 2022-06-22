//
//  SearchToiletResultCollectionHeaderView.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2022/05/09.
//

import Foundation
import UIKit

class SearchToiletResultCollectionHeaderView: UICollectionReusableView {

  private weak var label: UILabel?

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
    self.label = label
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    label?.removeFromSuperview()
  }
}
