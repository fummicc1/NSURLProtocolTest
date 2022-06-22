//
//  TabController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/11.
//

import Foundation
import SFSafeSymbols
import UIKit

class TabBarController: UITabBarController {

  private weak var homeViewController: HomeViewController?
  private weak var settingsViewController: SettingsViewController?
  private weak var toiletTabViewController: ToiletTabViewController?
  private weak var toiletDiaryListViewController: ToiletDiaryListViewController?
  private let showTutorial: Bool

  init(showTutorial: Bool) {
    self.showTutorial = showTutorial
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("Not Implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let toiletTabViewController = ToiletTabViewController()
    let homeViewController = HomeViewController(showTutorial: showTutorial)
    let settingsViewController = SettingsViewController()

    let userRepository = Repositories.userRepository!
    let toiletRepository = Repositories.toiletRepository!
    let diaryRepository = Repositories.toiletDiaryRepository!
    let mapper = ToiletDiaryMapper()
    let toiletDiaryUseCase = ToiletDiaryUseCase(
      mapper: mapper,
      userRepository: userRepository,
      toiletRepository: toiletRepository,
      toiletDiaryRepository: diaryRepository
    )

    let currentLocationUseCase = LocationUseCase.GetCurrentLocationUseCase()

    let dependency = ToiletDiaryListViewModel.Dependency(
      syncLocalAndRemoteToiletDiaryUseCase: toiletDiaryUseCase,
      observeListUseCase: toiletDiaryUseCase,
      currentLocationUseCase: currentLocationUseCase
    )

    let toiletDiaryListViewModel = ToiletDiaryListViewModel(dependency: dependency)
    let toiletDiaryListViewController = ToiletDiaryListViewController(
      viewModel: toiletDiaryListViewModel)

    let firstItem = UITabBarItem(
      title: "探す", image: UIImage(systemSymbol: .map), selectedImage: UIImage(systemSymbol: .map))

    let toiletImage = UIImage(named: "icon_72_72") ?? UIImage(systemSymbol: .heart)
    let secondItem = UITabBarItem(title: "マイトイレ", image: toiletImage, selectedImage: toiletImage)
    let thirdItem = UITabBarItem(
      title: "日記", image: UIImage(systemSymbol: .note), selectedImage: UIImage(systemSymbol: .note))
    let fourthItem = UITabBarItem(
      title: "設定", image: UIImage(systemSymbol: .gearshape),
      selectedImage: UIImage(systemSymbol: .gearshape))

    let firstNavigationController = NavigationController(
      rootViewController: homeViewController
    )
    firstNavigationController.tabBarItem = firstItem

    let secondNavigationController = NavigationController(
      rootViewController: toiletTabViewController)
    secondNavigationController.view.backgroundColor = AppColor.backgroundColor
    secondNavigationController.tabBarItem = secondItem

    let thirdNavigationController = NavigationController(
      rootViewController: toiletDiaryListViewController)
    thirdNavigationController.tabBarItem = thirdItem

    let fourthNavigationController = NavigationController(
      rootViewController: settingsViewController)
    fourthNavigationController.tabBarItem = fourthItem

    setViewControllers(
      [
        firstNavigationController, secondNavigationController, thirdNavigationController,
        fourthNavigationController,
      ], animated: true)

    self.homeViewController = homeViewController
    self.toiletTabViewController = toiletTabViewController
    self.settingsViewController = settingsViewController
    self.toiletDiaryListViewController = toiletDiaryListViewController

    // iOS15以上の対応
    if #available(iOS 15.0, *) {
      let appearance = UITabBarAppearance()
      appearance.backgroundColor = AppColor.backgroundColor
      UITabBar.appearance().scrollEdgeAppearance = appearance
    }
  }
}
