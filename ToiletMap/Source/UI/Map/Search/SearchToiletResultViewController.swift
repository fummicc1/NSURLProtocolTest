//
//  SearchToiletResultViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2022/05/06.
//

import CoreLocation
import Foundation
import NVActivityIndicatorView
import UIKit

class SearchToiletResultViewController: UICollectionViewController {

  private(set) var dataSource: UICollectionViewDiffableDataSource<Section, ToiletFragment>?

  private(set) weak var delegate: SearchToiletResultViewControllerDelegate?

  init(
    delegate: SearchToiletResultViewControllerDelegate?
  ) {
    self.delegate = delegate
    super.init(collectionViewLayout: Self.createLayout())
    // MARK: setup
    let cellRegistration: UICollectionView.CellRegistration<SearchResultCell, ToiletFragment> =
      .init(handler: { (cell, indexPath, toilet) in
        let coordinate =
          LocationShared.default.locationManager.location?.coordinate ?? CLLocationCoordinate2D()
        let distance = coordinate.calculateDistance(with: toilet.coordinate)
        cell.configure(
          toilet: toilet,
          distance: distance
        ) {
          self.delegate?.searchViewController(self, didTapToilet: toilet)
        }
      })
    let headerRegistration = UICollectionView.SupplementaryRegistration<
      SearchToiletResultCollectionHeaderView
    >(
      elementKind: Self.className
    ) { supplementaryView, elementKind, indexPath in
      if indexPath.section == 0 {
        supplementaryView.addText("300メートル以内")
      } else {
        supplementaryView.addText("300メートル以上離れています")
      }
    }

    self.dataSource = .init(
      collectionView: collectionView
    ) { collectionView, indexPath, toilet in
      let cell = collectionView.dequeueConfiguredReusableCell(
        using: cellRegistration,
        for: indexPath,
        item: toilet
      )
      return cell
    }

    dataSource?.supplementaryViewProvider = { collectionView, elementKind, indexPath in
      let header = collectionView.dequeueConfiguredReusableSupplementary(
        using: headerRegistration,
        for: indexPath
      )
      return header
    }
  }

  required init?(coder: NSCoder) {
    fatalError()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.backgroundColor = AppColor.backgroundColor
  }

  private static func createLayout() -> UICollectionViewCompositionalLayout {

    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .fractionalHeight(1.0)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(0.4),
      heightDimension: .fractionalHeight(1.0)
    )
    let group = NSCollectionLayoutGroup.vertical(
      layoutSize: groupSize,
      subitem: item,
      count: 2
    )
    group.interItemSpacing = .fixed(4)

    let config = UICollectionViewCompositionalLayoutConfiguration()
    config.scrollDirection = .horizontal

    let section = NSCollectionLayoutSection(group: group)
    section.interGroupSpacing = 12
    section.contentInsets = .init(top: 40, leading: 40, bottom: 40, trailing: 40)
    section.boundarySupplementaryItems = [
      NSCollectionLayoutBoundarySupplementaryItem(
        layoutSize: .init(
          widthDimension: .fractionalWidth(1.0),
          heightDimension: .absolute(44)
        ),
        elementKind: Self.className,
        alignment: .topLeading
      )
    ]

    return UICollectionViewCompositionalLayout(
      section: section,
      configuration: config
    )
  }
}

extension SearchToiletResultViewController {
  enum Section: String {
    case near
    case far
  }
}

protocol SearchToiletResultViewControllerDelegate: AnyObject {
  func searchViewController(
    _ searchViewController: SearchToiletResultViewController, didTapToilet toilet: ToiletPresentable
  )
}
