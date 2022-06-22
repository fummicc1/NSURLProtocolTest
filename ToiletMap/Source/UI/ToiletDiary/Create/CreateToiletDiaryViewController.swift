//
//  CreateToiletDiaryViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/08/03.
//

import CoreLocation
import Foundation
import RxSwift
import UIKit

class CreateToiletDiaryViewController: BaseViewController {

  private var contentView: EditToiletDiaryView {
    view as! EditToiletDiaryView
  }

  let viewModel: CreateToiletDiaryViewModelType

  private let formatter = DateFormatter()

  init(viewModel: CreateToiletDiaryViewModelType) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    view = EditToiletDiaryView(mode: .create)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureNavigationBar()
    configureViewModel()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    view.bounds = UIScreen.main.bounds
  }
}

extension CreateToiletDiaryViewController {

  private func configureNavigationBar() {
    navigationItem.title = "日記作成"
    navigationItem.leftBarButtonItem = BarButtonItem(
      barButtonSystemItem: .close, target: self, action: #selector(closeViewController))
  }

  private func configureViewModel() {

    // MARK: Views
    let memoTextView: PlaceholderTextView = contentView.memoTextView
    let datePicker: UIDatePicker = contentView.datePicker
    let peeButton: UIButton = contentView.peeButton
    let poopButton: UIButton = contentView.poopButton
    let peeAndPoopButton: UIButton = contentView.peeAndPoopButton
    let saveButton: UIButton = contentView.saveButton
    let diaryTimeLabel: UILabel = contentView.diaryTimeLabel
    let diaryDateLabel: UILabel = contentView.diaryDateLabel

    // MARK: Input
    let memo = memoTextView.rx.text.orEmpty
    let date = datePicker.rx.date.asObservable()

    let didTapPeeButton = peeButton.rx.tap.map({ ToiletDiaryType.pee })
    let didTapPoopButton = poopButton.rx.tap.map({ ToiletDiaryType.poop })
    let didTapPeeAndPoopButton = peeAndPoopButton.rx.tap.map({ ToiletDiaryType.peeAndPoop })

    memo
      .subscribe(onNext: { [weak self] memo in
        self?.viewModel.update(memo: memo)
      })
      .disposed(by: disposeBag)

    date
      .subscribe(onNext: { [weak self] date in
        self?.viewModel.update(date: date)
      })
      .disposed(by: disposeBag)

    Observable.merge(didTapPeeButton, didTapPoopButton, didTapPeeAndPoopButton)
      .subscribe(onNext: { [weak self] diaryType in
        self?.viewModel.update(type: diaryType)
      })
      .disposed(by: disposeBag)

    saveButton.rx.tap.subscribe(onNext: { [weak self] in
      self?.viewModel.save()
    }).disposed(by: disposeBag)

    // MARK: Output

    viewModel.diaryType.subscribe(onNext: { diaryType in

      peeButton.isSelected = false
      poopButton.isSelected = false
      peeAndPoopButton.isSelected = false

      switch diaryType {
      case .pee:
        peeButton.isSelected = true

      case .poop:
        poopButton.isSelected = true

      case .peeAndPoop:
        peeAndPoopButton.isSelected = true

      case .other:
        break
      }
    })
    .disposed(by: disposeBag)

    viewModel.date.map({ date in
      self.formatter.dateStyle = .none
      self.formatter.timeStyle = .short
      return self.formatter.string(from: date)
    })
    .bind(to: diaryTimeLabel.rx.text)
    .disposed(by: disposeBag)

    viewModel.date.map({ date in
      self.formatter.dateStyle = .short
      self.formatter.timeStyle = .none
      return self.formatter.string(from: date)
    })
    .bind(to: diaryDateLabel.rx.text)
    .disposed(by: disposeBag)

    viewModel.errorMessage.subscribe(onNext: { [weak self] message in
      self?.showErrorMessage(message)
    }).disposed(by: disposeBag)

    viewModel.completeRecordingToiletDiary.subscribe(onNext: { [weak self] in
      self?.showSimpleAlert(
        title: "日記を作成しました", message: nil, buttonTitle: "閉じる",
        handler: { [weak self] _ in
          self?.dismiss(animated: true, completion: nil)
        })
    }).disposed(by: disposeBag)
  }

  @objc
  private func closeViewController() {
    dismiss(animated: true, completion: nil)
  }
}

extension CreateToiletDiaryViewController {
  static func build(location: CLLocationCoordinate2D) -> CreateToiletDiaryViewController {
    let useCase = ToiletDiaryUseCase(
      mapper: ToiletDiaryMapper(),
      userRepository: Repositories.userRepository,
      toiletRepository: Repositories.toiletRepository,
      toiletDiaryRepository: Repositories.toiletDiaryRepository
    )

    let dependency = CreateToiletDiaryViewModel.Dependency(
      createToiletDiaryUseCase: useCase,
      updateToiletDiaryUseCase: useCase,
      deleteToiletDiaryUseCase: useCase
    )

    let viewModel = CreateToiletDiaryViewModel(
      dependency: dependency,
      location: CLLocationCoordinate2D(
        latitude: location.latitude,
        longitude: location.longitude
      )
    )

    let viewController = CreateToiletDiaryViewController(
      viewModel: viewModel
    )

    return viewController
  }
}
