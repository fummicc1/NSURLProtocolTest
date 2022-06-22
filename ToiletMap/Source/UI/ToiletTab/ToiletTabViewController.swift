//
//  ToiletTabViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/13.
//

import Foundation
import UIKit

protocol ToiletTabViewControllerDelegate: AnyObject {
  func didSelectToilet(_ toilet: Entity.Toilet)
  func didSelectArchivedToilet(_ archivedToilet: Entity.ArchivedToilet)
}

class ToiletTabViewController: BaseViewController {

  weak var delegate: ToiletTabViewControllerDelegate?

  private let pageViewController = ToiletTabPageViewController()

  private let firstItem = ToiletTabLayoutItem(index: 0, text: "保存")
  private let secondItem = ToiletTabLayoutItem(index: 1, text: "作成")
  private let thirdItem = ToiletTabLayoutItem(index: 2, text: "レビュー")

  private var items: [ToiletTabLayoutItem] {
    [firstItem, secondItem, thirdItem]
  }

  private lazy var onSelect = { (index: Int) in
    self.items.forEach { item in
      item.updateState(isSelected: item.index == index)
    }
    let pageViewController = self.pageViewController
    pageViewController.move(to: index)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.title = "マイトイレ"

    let stackView = UIStackView(arrangedSubviews: [
      firstItem,
      secondItem,
      thirdItem,
    ])

    [firstItem, secondItem, thirdItem].forEach { item in
      item.handleSelect(handler: onSelect)
    }

    pageViewController.setPageDelegate(pageDelegate: self)

    stackView.distribution = .fillEqually
    stackView.backgroundColor = AppColor.backgroundColor
    stackView.axis = .horizontal
    stackView.spacing = 0

    addChild(pageViewController)
    pageViewController.didMove(toParent: self)

    let contentStackView = UIStackView(arrangedSubviews: [
      stackView,
      pageViewController.view,
    ])
    contentStackView.axis = .vertical
    contentStackView.spacing = 0

    view.addSubview(contentStackView)

    contentStackView.snp.makeConstraints { (constraint) in
      constraint.top.bottom.leading.trailing.equalTo(view.safeAreaLayoutGuide)
    }

    firstItem.updateState(isSelected: true)
    secondItem.updateState(isSelected: false)
    thirdItem.updateState(isSelected: false)
  }
}

extension ToiletTabViewController: ToiletTabPageViewControllerDelegate {
  func didScrollPage(to index: Int) {
    items.forEach { item in
      item.updateState(isSelected: item.index == index)
    }
  }
}
