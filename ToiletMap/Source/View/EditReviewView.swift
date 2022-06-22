//
//  EditReviewView.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/07/13.
//

import Foundation
import UIKit

class EditReviewView: XibView {

  @IBOutlet private var canUseSwitch: ColoredSwitch!
  @IBOutlet private var isFreeSwitch: ColoredSwitch!
  @IBOutlet private var hasWashletSwitch: ColoredSwitch!
  @IBOutlet private var hasAccessibleRestroomSwitch: ColoredSwitch!
  @IBOutlet private var commitButton: UIButton!

  private var review: ReviewPresentable
  private let onChangeCommited: (ReviewPresentable) -> Void

  init(review: ReviewPresentable, onChangeCommited: @escaping (ReviewPresentable) -> Void) {
    self.review = review
    self.onChangeCommited = onChangeCommited
    super.init(frame: .zero)

    canUseSwitch.isOn = review.canUse
    isFreeSwitch.isOn = review.isFree
    hasWashletSwitch.isOn = review.hasWashlet
    hasAccessibleRestroomSwitch.isOn = review.hasAccessibleRestroom

    // Color
    commitButton.backgroundColor = AppColor.mainColor

    layer.cornerRadius = 8
    _view.layer.cornerRadius = 8
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @IBAction private func onCommit() {
    review.canUse = canUseSwitch.isOn
    review.isFree = isFreeSwitch.isOn
    review.hasWashlet = hasWashletSwitch.isOn
    review.hasAccessibleRestroom = hasAccessibleRestroomSwitch.isOn

    onChangeCommited(review)
  }
}
