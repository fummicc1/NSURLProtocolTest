//
//  AppDelegate.swift
//  NewToiletCritic
//
//  Created by 田中郁弥 on 2018/04/24.
//  Copyright © 2018年 fumiya. All rights reserved.
//

import Firebase
import FirebaseFirestore
import MapKit
import RxCocoa
import RxSwift
import SwiftyUserDefaults
import Swinject
import UIKit

struct Repositories {
  static var userRepository: UserRepositoryType!
  static var authRepository: AuthRepositoryType!
  static var toiletRepository: ToiletRepositoryType!
  static var reviewRepository: ReviewRepositoryType!
  static var toiletDiaryRepository: ToiletDiaryRepositoryType!
  static var mapItemRepository: MapItemRepositoryType!

  static func configure(with resolver: Resolver) {
    userRepository = resolver.resolve(UserRepositoryType.self)!
    authRepository = resolver.resolve(AuthRepositoryType.self)!
    toiletRepository = resolver.resolve(ToiletRepositoryType.self)!
    reviewRepository = resolver.resolve(ReviewRepositoryType.self)!
    toiletDiaryRepository = resolver.resolve(ToiletDiaryRepositoryType.self)!
    mapItemRepository = resolver.resolve(MapItemRepositoryType.self)!
  }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  private let disposeBag = DisposeBag()
  private var colorObserverToken: DefaultsDisposable?

  private var assembler: Assembler?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    assembler = Assembler([
      FirebaseAssembly(),
      RepositoryAssembly(),
    ])

    Repositories.configure(with: assembler!.resolver)

    Repositories.authRepository
      .user
      .share()
      .debounce(.milliseconds(10), scheduler: MainScheduler.instance)
      .filter({ $0?.uid == nil })
      .do(onNext: { _ in
        Repositories.toiletRepository.clearAllToilets()
        Repositories.reviewRepository.clearMyReviews()
      })
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { _ in
        self.window?.rootViewController = NavigationController(
          rootViewController: OnboardingViewController())
        self.window?.makeKeyAndVisible()
      })
      .disposed(by: disposeBag)

    Repositories.authRepository
      .user
      .share()
      .compactMap({ $0 })
      .debounce(.milliseconds(10), scheduler: MainScheduler.instance)
      .flatMap { authUser in
        Repositories.userRepository.get(uid: authUser.uid)
          .asObservable()
          .catch({ _ -> Observable<Entity.User> in
            Repositories.userRepository
              .create(authUser: authUser)
              .flatMap({
                Repositories.userRepository.get(uid: authUser.uid)
              })
              .asObservable()
          })
          .flatMap({ entityUser in
            Repositories.userRepository.update(entityUser, from: authUser)
          })
      }
      .subscribe()
      .disposed(by: disposeBag)

    UserDefaults.standard.register(defaults: [
      "is_accepted_rules": false,
      "should_show_tutorial": true,
    ])

    let prefs = UserDefaults.standard
    window = UIWindow()

    AppColor.mainColor = UIColor(hex: Defaults[\.mainColor].hexString)

    window?.tintColor = AppColor.mainColor

    if prefs.bool(forKey: "is_accepted_rules") {
      window?.rootViewController = TabBarController(showTutorial: false)
    } else {
      window?.rootViewController = NavigationController(
        rootViewController: OnboardingViewController())
    }
    window?.makeKeyAndVisible()

    colorObserverToken = Defaults.observe(\.mainColor) { [weak self] (update) in
      if let hexColor = update.newValue {
        AppColor.mainColor = UIColor(hex: hexColor.hexString)
        self?.reloadAllViewsAppearance()
      }
    }

    return true
  }

  private func reloadAllViewsAppearance() {
    let rootViewController = TabBarController(showTutorial: false)
    rootViewController.view.alpha = 0
    window?.tintColor = AppColor.mainColor
    window?.rootViewController = rootViewController
    window?.makeKeyAndVisible()

    UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut]) {
      rootViewController.view.alpha = 1
    }

    Repositories.authRepository.reload()
    Repositories.userRepository.reload()
    Repositories.toiletRepository.reload()
    MapItemRepository.shared.reload()
  }
}
