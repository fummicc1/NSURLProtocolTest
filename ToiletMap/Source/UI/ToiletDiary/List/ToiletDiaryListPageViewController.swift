//
//  ToiletDiaryListPageViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/08/17.
//

import Foundation
import UIKit

class ToiletDiaryListPageViewController: UIPageViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    dataSource = self
    delegate = self
  }

}

extension ToiletDiaryListPageViewController: UIPageViewControllerDelegate,
  UIPageViewControllerDataSource
{
  func pageViewController(
    _ pageViewController: UIPageViewController,
    viewControllerBefore viewController: UIViewController
  ) -> UIViewController? {
    nil
  }

  func pageViewController(
    _ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController
  ) -> UIViewController? {
    nil
  }

}
