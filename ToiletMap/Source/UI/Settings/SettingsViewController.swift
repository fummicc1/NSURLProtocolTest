//
//  SettingsViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/02/17.
//

import RxSwift
import SafariServices
import UIKit

class SettingsViewController: BaseViewController {

  enum Section: Hashable {
    case account
    case appStore
    case decorate
    case other
  }

  @IBOutlet private weak var collectionView: UICollectionView!

  private let viewModel: SettingsViewModelType = SettingsViewModel()

  private let layout: UICollectionViewCompositionalLayout = {
    var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
    config.headerMode = .supplementary
    let layout = UICollectionViewCompositionalLayout.list(using: config)
    return layout
  }()

  private lazy var dataSource: UICollectionViewDiffableDataSource<Section, SettingsData> = .init(
    collectionView: collectionView
  ) { (collectionView, indexPath, settingsData) -> UICollectionViewCell? in
    let cell: UICollectionViewCell
    if indexPath.section == 0, settingsData.isCustomCell {

      var _cell: UICollectionViewCell & SettingCollectionButtonCellType
      if indexPath.row == 1 {

        // サインアウト

        _cell =
          collectionView.dequeueReusableCell(
            withReuseIdentifier: SettingCollectionSignOutCell.className, for: indexPath)
          as! SettingCollectionSignOutCell
        _cell.action = {
          self.viewModel.showSignOutConfirmanceAlert()
        }
      } else {

        //
        _cell =
          collectionView.dequeueReusableCell(
            withReuseIdentifier: SettingCollectionSignInWithAppleCell.className, for: indexPath)
          as! SettingCollectionSignInWithAppleCell
        _cell.action = {
          self.viewModel.didSelectData(section: 0, index: 0)
        }

      }

      cell = _cell

    } else {
      cell = collectionView.dequeueConfiguredReusableCell(
        using: self.cellRegistration, for: indexPath, item: settingsData)
    }
    return cell
  }

  private let cellRegistration:
    UICollectionView.CellRegistration<UICollectionViewListCell, SettingsData> = .init {
      (cell, indexPath, settingsData) in
      var config = cell.defaultContentConfiguration()
      config.text = settingsData.title
      config.secondaryText = settingsData.detail
      config.image = settingsData.image
      cell.contentConfiguration = config
    }

  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.collectionViewLayout = layout

    navigationItem.title = "設定"

    collectionView.register(
      SettingCollectionSignInWithAppleCell.self,
      forCellWithReuseIdentifier: SettingCollectionSignInWithAppleCell.className)
    collectionView.register(
      SettingCollectionSignOutCell.self,
      forCellWithReuseIdentifier: SettingCollectionSignOutCell.className)

    let headerRegistration:
      UICollectionView.SupplementaryRegistration<SettingsCollectionHeaderView> = .init(
        elementKind: "UICollectionElementKindSectionHeader"
      ) { (header, elementKind, indexPath) in
        if indexPath.section == 0 {
          header.addText("アカウント")
        } else if indexPath.section == 1 {
          header.addText("アプリを応援する")
        } else if indexPath.section == 2 {
          header.addText("デコレーション")
        } else if indexPath.section == 3 {
          header.addText("その他")
        }
      }

    // Headerの設定
    dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
      return collectionView.dequeueConfiguredReusableSupplementary(
        using: headerRegistration, for: indexPath)
    }

    viewModel.errorMessage
      .subscribe(onNext: { [weak self] error in
        self?.showErrorMessage(error)
      })
      .disposed(by: disposeBag)

    viewModel.settingsData
      .subscribe(onNext: { [weak self] data in
        var snapshot = NSDiffableDataSourceSnapshot<Section, SettingsData>()
        snapshot.appendSections([.account, .appStore, .decorate, .other])
        for sectionData in data {
          let section = sectionData.first?.section ?? 0
          if section == 0 {
            snapshot.appendItems(sectionData, toSection: .account)
          } else if section == 1 {
            snapshot.appendItems(sectionData, toSection: .appStore)
          } else if section == 2 {
            snapshot.appendItems(sectionData, toSection: .decorate)
          } else if section == 3 {
            snapshot.appendItems(sectionData, toSection: .other)
          }
        }
        self?.dataSource.apply(snapshot)
      })
      .disposed(by: disposeBag)

    viewModel.showCreateHomeToiletViewController.subscribe(onNext: { [weak self] in
      let destination = CreateHomeToiletViewController()
      let navigationController = NavigationController(rootViewController: destination)
      self?.present(navigationController, animated: true, completion: nil)
    })
    .disposed(by: disposeBag)

    collectionView.rx.itemSelected
      .subscribe(onNext: { [weak self] indexPath in
        self?.viewModel.didSelectData(section: indexPath.section, index: indexPath.row)
      })
      .disposed(by: disposeBag)

    collectionView.rx
      .itemSelected
      .debounce(.milliseconds(10), scheduler: MainScheduler.instance)
      .subscribe(onNext: { [weak self] indexPath in
        self?.collectionView.deselectItem(at: indexPath, animated: true)
      })
      .disposed(by: disposeBag)

    viewModel.showColorPicker
      .subscribe(onNext: { [weak self] pickerController in
        pickerController.delegate = self
        self?.present(pickerController, animated: true, completion: nil)
      })
      .disposed(by: disposeBag)

    viewModel.showSignInAccountAlreadyLinkedWithAppleIdPrompt.subscribe(onNext: { [weak self] in
      self?.showSimpleAlert(
        title: "AppleIDが既に他のアカウントと連携がされています",
        message: "ご利用のAppleIDと連携済みのアカウントに変更しますか？\n現在は匿名状態のため変更後は再度ログインできなくなります",
        buttonTitle: "連携済みのアカウントに変更",
        buttonStyle: .default,
        handler: { _ in
          self?.viewModel.performSignInAccountAlreadyLinkedWithAppleId()
        },
        secondButtonTitle: "キャンセル",
        secondButtonStyle: .cancel,
        completion: nil
      )
    }).disposed(by: disposeBag)

    viewModel.showDeleteAccountConfirmation.subscribe(onNext: { [weak self] in
      let alert = UIAlertController(
        title: "アカウントを削除しますか？", message: "この操作は取り消すことができません", preferredStyle: .alert)
      alert.addAction(
        UIAlertAction(
          title: "削除", style: .destructive,
          handler: { _ in
            self?.viewModel.acceptDeleteAccount()
          }))
      alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
      self?.present(alert, animated: true, completion: nil)
    })
    .disposed(by: disposeBag)

    viewModel.showSignOutConfirmation.subscribe(onNext: { [weak self] in
      let alert = UIAlertController(
        title: "現在のアカウントからサインアウトしますか？", message: nil, preferredStyle: .alert)
      alert.addAction(
        UIAlertAction(
          title: "サインアウト", style: .destructive,
          handler: { _ in
            self?.viewModel.acceptSignOut()
          }))
      alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
      self?.present(alert, animated: true, completion: nil)
    })
    .disposed(by: disposeBag)

    let urlStreams = Observable.merge(viewModel.showPrivacyPolicy, viewModel.showTermsAndCondition)

    urlStreams.subscribe(onNext: { [weak self] url in
      let viewController = SFSafariViewController(url: url)
      self?.present(viewController, animated: true, completion: nil)
    })
    .disposed(by: disposeBag)

  }
}

extension SettingsViewController: UIColorPickerViewControllerDelegate {
  func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
    let color = viewController.selectedColor
    viewModel.didChoiceMainColor(color: color)
  }
}
