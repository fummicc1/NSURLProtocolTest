//
//  ReviewToiletListViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/17.
//

import Foundation
import RxSwift
import UIKit

class ReviewToiletListViewController: BaseViewController {
  private let viewModel: ReviewToiletListViewModelType = ReviewToiletListViewModel()

  @IBOutlet private weak var collectionView: UICollectionView!

  private lazy var emptyStateView: EmptyStateView = EmptyStateView(
    text: "レビューをしたトイレが一覧で表示されます。",
    image: nil,
    didTap: {}
  )

  weak var delegate: ToiletListViewControllerDelegate?

  private lazy var layout: UICollectionViewCompositionalLayout = {
    let imageConfiguration: UIImage.SymbolConfiguration = .init(
      font: UIFont.preferredFont(forTextStyle: .title3), scale: .medium)
    var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
    config.headerMode = UICollectionLayoutListConfiguration.HeaderMode.none
    let list = UICollectionViewCompositionalLayout.list(using: config)
    return list
  }()

  private lazy var dataSource: UICollectionViewDiffableDataSource<Section, ToiletFragment> =
    UICollectionViewDiffableDataSource(collectionView: collectionView) {
      [weak self] (collectionView, indexPath, toilet) -> UICollectionViewCell? in
      guard let self = self else {
        return nil
      }
      let cell = collectionView.dequeueConfiguredReusableCell(
        using: self.cellRegistration, for: indexPath, item: toilet)
      return cell
    }

  private let cellRegistration = UICollectionView.CellRegistration<
    UICollectionViewListCell, ToiletFragment
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

    collectionView.collectionViewLayout = layout

    viewModel.reviewToiletList
      .map({ $0.compactMap({ $0 as? ToiletFragment }) })
      .subscribe(onNext: { [weak self] toilets in
        var snapshot = NSDiffableDataSourceSnapshot<Section, ToiletFragment>()
        snapshot.appendSections([.main])
        snapshot.appendItems(toilets)
        self?.dataSource.apply(snapshot)
      })
      .disposed(by: disposeBag)

    viewModel.reviewToiletList
      .map({ $0.isEmpty })
      .subscribe(onNext: { [weak self] isEmpty in
        self?.emptyStateView.isHidden = isEmpty.reverse()
      })
      .disposed(by: disposeBag)

    let reviewAndToilets = Observable.combineLatest(
      viewModel.reviewToiletList,
      viewModel.reviews
    )

    collectionView.rx.itemSelected
      .withLatestFrom(reviewAndToilets) { indexPath, listTuple in
        (listTuple.0[indexPath.row], listTuple.1[indexPath.row])
      }
      .subscribe(onNext: { (toilet, review) in
        let focusViewController = FocusReviewToiletViewController(review: review, toilet: toilet)
        self.navigationController?.pushViewController(focusViewController, animated: true)
      })
      .disposed(by: disposeBag)
  }
}

extension ReviewToiletListViewController {
  enum Section: Hashable {
    case main
  }
}
