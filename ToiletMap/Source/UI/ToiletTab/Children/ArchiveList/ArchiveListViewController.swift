//
//  ArchiveListViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/03/28.
//

import RxCocoa
import RxSwift
import SFSafeSymbols
import UIKit

protocol ArchiveListViewControllerDelegate: AnyObject {
  func didSelectArchivedToilet(
    _ viewController: ArchiveListViewController, toilet: ArchivedToiletPresentable)
}

class ArchiveListViewController: BaseViewController {

  @IBOutlet weak var collectionView: UICollectionView!

  private let viewModel: ArchiveListViewModelOutput = ArchiveListViewModel()
  private lazy var emptyStateView = EmptyStateView(
    text: "保存したトイレが一覧で表示されます。",
    image: nil,
    didTap: {}
  )
  weak var delegate: ArchiveListViewControllerDelegate?

  private lazy var layout: UICollectionViewCompositionalLayout = {
    let imageConfiguration: UIImage.SymbolConfiguration = .init(
      font: UIFont.preferredFont(forTextStyle: .title3), scale: .medium)
    var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
    config.headerMode = UICollectionLayoutListConfiguration.HeaderMode.none
    let layout = UICollectionViewCompositionalLayout.list(using: config)
    return layout
  }()
  private lazy var dataSource = UICollectionViewDiffableDataSource<Section, ArchivedToiletFragment>(
    collectionView: collectionView
  ) { [weak self] (collectionView, indexPath, item) -> UICollectionViewCell? in
    guard let self = self else {
      return nil
    }
    let cell = collectionView.dequeueConfiguredReusableCell(
      using: self.cellRegistration, for: indexPath, item: item)
    return cell
  }
  private let cellRegistration = UICollectionView.CellRegistration<
    UICollectionViewListCell, ArchivedToiletFragment
  > { (cell, indexPath, toilet) in
    var configuration = cell.defaultContentConfiguration()
    configuration.text = toilet.name
    configuration.secondaryText = toilet.detail
    cell.contentConfiguration = configuration
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(emptyStateView)

    emptyStateView.snp.makeConstraints { (constraint) in
      constraint.top.leading.equalToSuperview().offset(24)
      constraint.trailing.equalToSuperview().offset(-16)
      constraint.height.equalTo(120)
    }

    emptyStateView.configureInitialLayout()

    viewModel.archiveList
      .map({ $0.compactMap({ $0 as? ArchivedToiletFragment }) })
      .subscribe(onNext: { [weak self] toilets in
        guard let self = self else {
          return
        }
        var snapshot = NSDiffableDataSourceSnapshot<Section, ArchivedToiletFragment>()
        snapshot.appendSections([.main])
        snapshot.appendItems(toilets, toSection: .main)
        self.dataSource.apply(snapshot)
      })
      .disposed(by: disposeBag)

    viewModel.archiveList.map({ $0.isEmpty })
      .subscribe(onNext: { [weak self] isEmpty in
        self?.emptyStateView.isHidden = isEmpty.reverse()
      })
      .disposed(by: disposeBag)

    collectionView.collectionViewLayout = layout

    collectionView.rx.itemSelected.withLatestFrom(viewModel.archiveList) {
      (indexPath, list) -> ArchivedToiletPresentable in
      self.collectionView.deselectItem(at: indexPath, animated: true)
      return list[indexPath.row]
    }.subscribe(onNext: { [weak self] toilet in
      guard let self = self else {
        return
      }
      let focusViewController = FocusToiletViewController(toilet: toilet)
      self.navigationController?.pushViewController(focusViewController, animated: true)
    })
    .disposed(by: disposeBag)
  }
}

extension ArchiveListViewController {
  enum Section: Hashable {
    case main
  }
}
