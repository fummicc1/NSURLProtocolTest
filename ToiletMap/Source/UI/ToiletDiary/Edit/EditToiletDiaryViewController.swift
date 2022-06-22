//
//  EditToiletDiaryViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/08/16.
//

import RxSwift
import UIKit

class EditToiletDiaryViewController: BaseViewController {

  private var contentView: EditToiletDiaryView {
    view as! EditToiletDiaryView
  }

  private let viewModel: EditToiletDiaryViewModelType
  private let toiletDiary: ToiletDiaryPresentable

  init(viewModel: EditToiletDiaryViewModelType, toiletDiary: ToiletDiaryPresentable) {
    self.viewModel = viewModel
    self.toiletDiary = toiletDiary
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    view = EditToiletDiaryView(mode: .update)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureNavigationBar()
    configureViewModel()
    configureInitialUI()
  }

  private func configureNavigationBar() {
    navigationItem.title = "日記編集"
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
    let deleteButton: UIButton = contentView.deleteButton

    // MARK: Input
    // 最初の初期状態をスキップする
    let memo = memoTextView.rx.text.orEmpty.skip(1)
    let date = datePicker.rx.date.skip(1)

    let didTapPeeButton = peeButton.rx.tap.map({ ToiletDiaryType.pee })
    let didTapPoopButton = poopButton.rx.tap.map({ ToiletDiaryType.poop })
    let didTapPeeAndPoopButton = peeAndPoopButton.rx.tap.map({ ToiletDiaryType.peeAndPoop })
    let didTapDeleteButton = deleteButton.rx.tap

    memo.subscribe(onNext: { [weak self] memo in
      self?.viewModel.update(memo: memo)
    })
    .disposed(by: disposeBag)

    date.subscribe(onNext: { [weak self] date in
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

    didTapDeleteButton.subscribe(onNext: { [weak self] in
      self?.showSimpleAlert(
        title: "日記を削除しますか？",
        message: "この操作は取り消せません",
        buttonTitle: "削除",
        buttonStyle: .destructive,
        handler: { [weak self] _ in
          self?.viewModel.delete()
        },
        secondButtonTitle: "キャンセル",
        secondButtonStyle: .cancel
      )
    }).disposed(by: disposeBag)

    // MARK: Output

    viewModel.memo.subscribe { memo in
      memoTextView.text = memo
    }
    .disposed(by: disposeBag)

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
      let formatter = DateFormatter()
      formatter.dateStyle = .none
      formatter.timeStyle = .short
      return formatter.string(from: date)
    })
    .bind(to: diaryTimeLabel.rx.text)
    .disposed(by: disposeBag)

    viewModel.date.map({ date in
      let formatter = DateFormatter()
      formatter.dateStyle = .short
      formatter.timeStyle = .none
      return formatter.string(from: date)
    })
    .bind(to: diaryDateLabel.rx.text)
    .disposed(by: disposeBag)

    viewModel.errorMessage.subscribe(onNext: { [weak self] message in
      self?.showErrorMessage(message)
    }).disposed(by: disposeBag)

    viewModel.completeSavingToiletDiary.subscribe(onNext: { [weak self] in
      self?.showSimpleAlert(
        title: "編集を保存しました", message: nil, buttonTitle: "閉じる",
        handler: { [weak self] _ in
          self?.dismiss(animated: true, completion: nil)
        })
    }).disposed(by: disposeBag)

    viewModel.completeDeletingToiletDiary.subscribe(onNext: { [weak self] in
      self?.showSimpleAlert(
        title: "日記を削除しました", message: nil, buttonTitle: "閉じる",
        handler: { [weak self] _ in
          self?.dismiss(animated: true, completion: nil)
        })
    })
    .disposed(by: disposeBag)
  }

  private func configureInitialUI() {
    contentView.datePicker.setDate(toiletDiary.date, animated: true)
  }

  @objc
  private func closeViewController() {
    dismiss(animated: true, completion: nil)
  }
}

extension EditToiletDiaryViewController {
  static func build(parameter: EditToiletDiaryInitializeParameter) -> EditToiletDiaryViewController
  {
    let useCase = ToiletDiaryUseCase(
      mapper: ToiletDiaryMapper(),
      userRepository: Repositories.userRepository,
      toiletRepository: Repositories.toiletRepository,
      toiletDiaryRepository: Repositories.toiletDiaryRepository
    )

    let dependency = EditToiletDiaryViewModel.Dependency(
      updateUseCase: useCase,
      deleteUseCase: useCase
    )

    let viewModel = EditToiletDiaryViewModel(
      parameter: parameter,
      dependency: dependency
    )

    let viewController = EditToiletDiaryViewController(
      viewModel: viewModel,
      toiletDiary: parameter.toiletDiary
    )

    return viewController
  }
}
