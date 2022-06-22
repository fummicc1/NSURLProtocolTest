//
//  EmptyStateView.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/20.
//

import Foundation
import UIKit

class EmptyStateView: UIView {

  let label: UILabel = UILabel(frame: .zero)
  let imageView: UIImageView = UIImageView(frame: .zero)
  let didTap: () -> Void

  init(text: String, image: UIImage?, didTap: @escaping () -> Void) {
    self.didTap = didTap
    label.text = text
    imageView.image = image
    super.init(frame: .zero)

    let tap = UITapGestureRecognizer(target: self, action: #selector(didTapGesture(sender:)))
    self.isUserInteractionEnabled = true
    addGestureRecognizer(tap)
  }

  required init?(coder: NSCoder) {
    fatalError()
  }

  @objc
  private func didTapGesture(sender: UITapGestureRecognizer) {
    if sender.state == .ended {
      didTap()
    }
  }

  func configureInitialLayout() {

    label.numberOfLines = 0
    label.font = UIFont.preferredFont(forTextStyle: .title2)
    imageView.contentMode = .scaleAspectFit

    addSubview(label)
    addSubview(imageView)
    label.snp.makeConstraints { (maker) in
      maker.top.equalToSuperview().offset(16)
      maker.leading.equalToSuperview().offset(16)
      maker.trailing.equalToSuperview().offset(-16)
      maker.bottom.equalTo(imageView.snp.top).offset(-8)
    }
    imageView.snp.makeConstraints { (maker) in
      maker.leading.trailing.equalTo(label)
      maker.bottom.equalToSuperview().offset(-8)
    }
  }
}
