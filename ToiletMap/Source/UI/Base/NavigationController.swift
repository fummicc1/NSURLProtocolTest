//
//  NavigationController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/02/14.
//

import Foundation
import UIKit

class NavigationController: UINavigationController {
  override func viewDidLoad() {
    super.viewDidLoad()
    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()
    appearance.titleTextAttributes = [
      .foregroundColor: AppColor.backgroundColor
    ]
    appearance.backgroundColor = AppColor.mainColor
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance

    navigationBar.topItem?.backButtonDisplayMode = .minimal
    navigationItem.backBarButtonItem?.tintColor = AppColor.backgroundColor
    navigationBar.tintColor = AppColor.backgroundColor
  }

  override func pushViewController(_ viewController: UIViewController, animated: Bool) {
    super.pushViewController(viewController, animated: animated)
    navigationBar.topItem?.backButtonDisplayMode = .minimal
  }
}
