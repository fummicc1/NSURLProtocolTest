//
//  ToiletDiaryListViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/08/03.
//

import Foundation
import UIKit

class ToiletDiaryListViewController: BaseViewController {

  @IBOutlet private weak var collectionView: UICollectionView!

  private lazy var emptyStateView = EmptyStateView(
    text: "ここにはトイレ詳細から作成した日記が表示されます", image: nil, didTap: {})

  private let viewModel: ToiletDiaryListViewModelType

  private let layout: UICollectionViewCompositionalLayout = {
    var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
    configuration.headerMode = .supplementary
    return .list(using: configuration)
  }()

  private var dataSource: UICollectionViewDiffableDataSource<Section, ToiletDiaryFragment>?

  private let cellRegistration:
    UICollectionView.CellRegistration<UICollectionViewListCell, ToiletDiaryFragment> = .init {
      cell, indexPath, fragment in
      var config = cell.defaultContentConfiguration()

      let formatter = DateFormatter()
      formatter.timeStyle = .short
      formatter.dateStyle = .none
      let formattedDate = formatter.string(from: fragment.date)

      config.imageProperties.reservedLayoutSize = CGSize(width: 32, height: 32)
      config.text = formattedDate
      config.secondaryText = fragment.memo
      config.image = UIImage(named: fragment.type.imageName)
      cell.contentConfiguration = config
    }

  init(viewModel: ToiletDiaryListViewModelType) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureViews()
    configureNavigationBar()
    configureCollectionView()
    configureViewModel()

    viewModel.viewDidLoad()
  }

}

extension ToiletDiaryListViewController {

  private func configureViews() {
    view.addSubview(emptyStateView)
    emptyStateView.snp.makeConstraints { maker in
      maker.top.bottom.left.trailing.equalTo(collectionView)
    }
    emptyStateView.configureInitialLayout()
  }

  private func configureNavigationBar() {
    navigationItem.title = "日記の一覧"
  }

  private func configureCollectionView() {
    collectionView.collectionViewLayout = layout
    let headerRegistration = UICollectionView.SupplementaryRegistration<
      ToiletDiaryListCollectionHeaderView
    >(
      elementKind: UICollectionView.elementKindSectionHeader
    ) { (header, elementKind, indexPath) in
      guard let section = self.dataSource?.snapshot().sectionIdentifiers[indexPath.section] else {
        return
      }
      if case Section.month(let date) = section {
        header.addText(date)
      }
    }
    let dataSource = UICollectionViewDiffableDataSource<Section, ToiletDiaryFragment>(
      collectionView: collectionView
    ) { collectionView, indexPath, diary in
      let cell = collectionView.dequeueConfiguredReusableCell(
        using: self.cellRegistration, for: indexPath, item: diary)
      return cell
    }
    dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
      collectionView.dequeueConfiguredReusableSupplementary(
        using: headerRegistration,
        for: indexPath
      )
    }

    collectionView.rx.itemSelected
      .subscribe(onNext: { [weak self] indexPath in
        self?.viewModel.didSelectDiary(at: indexPath)
      })
      .disposed(by: disposeBag)

    self.dataSource = dataSource
  }

  private func configureViewModel() {
    viewModel.diaryList.subscribe(onNext: { [weak self] list in
      var snapshot = NSDiffableDataSourceSnapshot<Section, ToiletDiaryFragment>()
      let dateFormatter = DateFormatter()
      dateFormatter.dateStyle = .short
      dateFormatter.timeStyle = .none
      var monthSeparated: [String: [ToiletDiaryFragment]] = [:]
      for diary in list {
        let month = dateFormatter.string(from: diary.date)
        if monthSeparated.keys.contains(month) {
          monthSeparated[month]?.append(diary)
        } else {
          monthSeparated[month] = [diary]
        }
      }
      for key in monthSeparated.keys.sorted().reversed() {
        guard let diaries = monthSeparated[key] else {
          continue
        }
        snapshot.appendSections([.month(key)])
        snapshot.appendItems(diaries, toSection: .month(key))
      }
      self?.dataSource?.apply(snapshot)
    })
    .disposed(by: disposeBag)

    viewModel.showEditToiletDiaryViewController
      .subscribe(onNext: { [weak self] parameter in

        let viewController = EditToiletDiaryViewController.build(parameter: parameter)

        let nav = NavigationController(rootViewController: viewController)

        nav.modalPresentationStyle = .fullScreen

        self?.present(nav, animated: true, completion: nil)
      })
      .disposed(by: disposeBag)

    viewModel.diaryList
      .map({ $0.isEmpty })
      .map({ $0 ? "まだ日記がありません" : "日記の一覧" })
      .bind(to: navigationItem.rx.title)
      .disposed(by: disposeBag)

    viewModel.diaryList
      .map({ $0.isEmpty })
      .subscribe(onNext: { [weak self] isEmpty in
        self?.emptyStateView.isHidden = isEmpty.reverse()
      })
      .disposed(by: disposeBag)
  }
}

extension ToiletDiaryListViewController {
  enum Section: Hashable {
    // month文字列（04/03など)
    case month(String)
  }
}
