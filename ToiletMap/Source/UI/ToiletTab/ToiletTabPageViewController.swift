//
//  ToiletTabPageViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/13.
//

import Foundation
import UIKit

protocol ToiletTabPageViewControllerDelegate: AnyObject {
  func didScrollPage(to index: Int)
}

class ToiletTabPageViewController: UIPageViewController {

  private var controllers: [UIViewController] = []
  private var currentIndex: Int = 0

  private weak var pageDelegate: ToiletTabPageViewControllerDelegate?

  init() {
    super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let archiveViewController = ArchiveListViewController()
    let createViewController = CreateToiletListViewController()
    let reviewViewController = ReviewToiletListViewController()

    controllers = [archiveViewController, createViewController, reviewViewController]

    setViewControllers(
      [archiveViewController], direction: .forward, animated: true, completion: nil)

    delegate = self
    dataSource = self

  }

  func move(to index: Int) {
    let viewController = controllers[index]
    setViewControllers(
      [viewController], direction: currentIndex > index ? .reverse : .forward, animated: true,
      completion: nil)
    currentIndex = index
  }

  func setPageDelegate(pageDelegate: ToiletTabPageViewControllerDelegate) {
    self.pageDelegate = pageDelegate
  }
}

extension ToiletTabPageViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource
{
  func pageViewController(
    _ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController
  ) -> UIViewController? {
    guard let index = controllers.firstIndex(of: viewController) else {
      return nil
    }

    if index == controllers.count - 1 {
      return nil
    }
    return controllers[index + 1]
  }

  func pageViewController(
    _ pageViewController: UIPageViewController,
    viewControllerBefore viewController: UIViewController
  ) -> UIViewController? {
    guard let index = controllers.firstIndex(of: viewController) else {
      return nil
    }

    if index == 0 {
      return nil
    }
    return controllers[index - 1]
  }

  func pageViewController(
    _ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
    previousViewControllers: [UIViewController], transitionCompleted completed: Bool
  ) {
    if !completed {
      return
    }
    // ViewControllersの最初には今表示するViewControllerが格納されている
    guard let viewController = viewControllers?.first else {
      return
    }
    guard let index = controllers.firstIndex(of: viewController) else {
      return
    }
    currentIndex = index
    pageDelegate?.didScrollPage(to: currentIndex)
  }
}
