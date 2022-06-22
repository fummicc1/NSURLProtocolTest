//
//  ToiletDiaryEditView.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/08/16.
//

import Foundation
import UIKit

class EditToiletDiaryView: XibView {

  enum ViewMode {
    case create
    case update
  }

  @IBOutlet weak var dateContainerView: UIView!

  @IBOutlet weak var datePicker: UIDatePicker!

  @IBOutlet weak var diaryDateLabel: UILabel!
  @IBOutlet weak var diaryTimeLabel: UILabel!

  @IBOutlet weak var peeButton: UIButton!
  @IBOutlet weak var poopButton: UIButton!
  @IBOutlet weak var peeAndPoopButton: UIButton!

  @IBOutlet weak var memoTextView: PlaceholderTextView!

  @IBOutlet weak var deleteButton: RadiusButton!
  @IBOutlet weak var saveButton: RadiusButton!

  private let mode: ViewMode

  init(mode: ViewMode) {
    self.mode = mode
    super.init(frame: .zero)
  }

  required init?(coder aDecoder: NSCoder) {
    self.mode = .create
    super.init(coder: aDecoder)
  }

  override func commonInit() {
    super.commonInit()
    configureViews()
    configureDatePicker()
    configureTextView()
    configureKeyboardObservation()
  }

  private func configureViews() {
    deleteButton.isHidden = mode == .create

    dateContainerView.layer.cornerRadius = 16
    dateContainerView.layer.masksToBounds = true

    let backgroundColor = AppColor.mainColor.withAlphaComponent(0.1)

    dateContainerView.backgroundColor = backgroundColor
    memoTextView.backgroundColor = backgroundColor

    saveButton.backgroundColor = AppColor.mainColor
  }

  private func configureDatePicker() {
    let calendar = Calendar.current
    var components = calendar.dateComponents(
      [.year, .month, .day, .hour, .minute, .hour], from: Date())
    components.calendar = calendar
    components.day? += 1
    components.hour = 0
    components.minute = 0
    components.second = 0
    datePicker.maximumDate = components.date
  }

  private func configureTextView() {
    memoTextView.configure(placeholder: "メモ入力欄")
    memoTextView.layer.cornerRadius = 8
  }

  private func configureKeyboardObservation() {
    let notificationCenter = NotificationCenter.default

    // キーボード表示時の処理
    notificationCenter.addObserver(
      forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .current
    ) { [weak self] notification in
      guard let self = self,
        let rect = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?
          .cgRectValue
      else {
        return
      }
      let keyboardHeight = rect.height
      let x: CGFloat = 0
      let y = self.bounds.height - keyboardHeight
      let intersectRect = CGRect(origin: CGPoint(x: x, y: y), size: rect.size)

      let convertedMemoTextViewFrame = self.memoTextView.convert(self.memoTextView.bounds, to: self)

      if convertedMemoTextViewFrame.intersects(intersectRect) {

        self.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)

      }
    }

    // キーボード非表示時の処理
    notificationCenter.addObserver(
      forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .current
    ) { [weak self] notification in
      guard let self = self,
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
          as? Double
      else {
        return
      }

      UIView.animate(withDuration: duration) {
        self.transform = .identity
      }
    }
  }
}
