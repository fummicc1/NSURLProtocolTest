//
//  ReviewViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/06.
//

import FirebaseFirestore
import Foundation
import RxCocoa
import RxSwift
import UIKit

class ReviewViewController: BaseViewController {

  @IBOutlet private var canUseSwitch: ColoredSwitch!
  @IBOutlet private var isFreeSwitch: ColoredSwitch!
  @IBOutlet private var hasWashletSwitch: ColoredSwitch!
  @IBOutlet private var hasAccessibleRestroomSwitch: ColoredSwitch!

  private let targetToilet: MapAnnotation
  private let viewModel: ReviewViewModelType

  init(storedMapAnnotation: MapAnnotation) {
    self.targetToilet = storedMapAnnotation
    self.viewModel = ReviewViewModel(storableToilet: storedMapAnnotation)
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    guard
      let view =
        UINib(nibName: Self.className, bundle: nil).instantiate(withOwner: self, options: nil).first
        as? UIView
    else {
      fatalError()
    }
    self.view = view
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configure()
  }

  private func configure() {
    let sendButton = BarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
    let dismissButton = BarButtonItem(barButtonSystemItem: .close, target: nil, action: nil)

    navigationItem.rightBarButtonItem = sendButton
    navigationItem.leftBarButtonItem = dismissButton
    navigationItem.title = "レビューをする"

    sendButton.rx.tap.subscribe { [weak self] (_) in
      guard let self = self else { return }
      self.viewModel.sendReview()
    }.disposed(by: disposeBag)

    viewModel.completeSendingReview.subscribe(onNext: { [weak self] in
      self?.dismiss(animated: true, completion: nil)
    }).disposed(by: disposeBag)

    viewModel.errorMessage.subscribe(onNext: { [weak self] error in
      self?.showErrorMessage(error)
      self?.feedback.notificationOccurred(.error)
    }).disposed(by: disposeBag)

    dismissButton.rx.tap.subscribe { [weak self] (_) in
      guard let self = self else { return }
      self.feedback.notificationOccurred(.success)
      self.dismiss(animated: true, completion: nil)
    }.disposed(by: disposeBag)

    canUseSwitch.rx.isOn
      .subscribe(onNext: { [weak self] isOn in
        self?.viewModel.updateField(field: .canUse, value: isOn)
      })
      .disposed(by: disposeBag)

    hasWashletSwitch.rx.isOn
      .subscribe(onNext: { [weak self] isOn in
        self?.viewModel.updateField(field: .hasWashlet, value: isOn)
      })
      .disposed(by: disposeBag)

    hasAccessibleRestroomSwitch.rx.isOn
      .subscribe(onNext: { [weak self] isOn in
        self?.viewModel.updateField(field: .hasAcccessibleRestroom, value: isOn)
      })
      .disposed(by: disposeBag)

    isFreeSwitch.rx.isOn
      .subscribe(onNext: { [weak self] isOn in
        self?.viewModel.updateField(field: .isFree, value: isOn)
      })
      .disposed(by: disposeBag)
  }

}
