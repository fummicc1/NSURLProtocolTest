//
//  SettingsViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/02/18.
//

import Foundation
import RxRelay
import RxSwift
import StoreKit
import SwiftyUserDefaults

protocol SettingsViewModelType {
  var didCompleteDeleteAccount: Observable<Void> { get }
  var didCompleteSignOut: Observable<Void> { get }
  var showSignOutConfirmation: Observable<Void> { get }
  var errorMessage: Observable<String> { get }
  var settingsData: Observable<[[SettingsData]]> { get }
  var showColorPicker: Observable<UIColorPickerViewController> { get }
  var showCreateHomeToiletViewController: Observable<Void> { get }
  var showSignInAccountAlreadyLinkedWithAppleIdPrompt: Observable<Void> { get }
  var showDeleteAccountConfirmation: Observable<Void> { get }

  var showTermsAndCondition: Observable<URL> { get }
  var showPrivacyPolicy: Observable<URL> { get }

  func showSignOutConfirmanceAlert()
  func performSignInAccountAlreadyLinkedWithAppleId()
  func didSelectData(section: Int, index: Int)
  func didChoiceMainColor(color: UIColor)
  func acceptDeleteAccount()
  func acceptSignOut()
}

struct SettingsData: Hashable {
  let section: Int
  let index: Int

  let title: String
  let detail: String?
  let image: UIImage?

  let type: ActionType

  let isCustomCell: Bool

  enum ActionType {
    case signInWithAppleLink
    case signOutAccount
    case delete
    case evaluate
    case writeReview
    case choiceMainColor
    case createHomeToilet
    case termsAndConditions
    case privacyPolicy
    case none
  }
}

class SettingsViewModel: BaseViewModel {

  private let errorMessageRelay: PublishRelay<String> = .init()
  private let didCompleteLinkWithAppleID: PublishRelay<Void> = .init()
  private let didCompleteDeleteAccountRelay: PublishRelay<Void> = .init()
  private let didCompleteSignOutRelay: PublishRelay<Void> = .init()
  private let showColorPickerRelay: PublishRelay<UIColorPickerViewController> = .init()
  private let showCreateHomeToiletViewContollerRelay: PublishRelay<Void> = .init()
  private let showSignInAccountAlreadyLinkedWithAppleIdPromptRelay: PublishRelay<Void> = .init()
  private let showDeleteAccountConfirmationRelay: PublishRelay<Void> = .init()
  private let showSignOutConfirmationRelay: PublishRelay<Void> = .init()
  private let acceptSignOutExecutionRelay: PublishRelay<Void> = .init()
  private let acceptDeleteAccountExecutionRelay: PublishRelay<Void> = .init()
  private let showPrivacyPolicyRelay: PublishRelay<URL> = .init()
  private let showTermAndConditionRelay: PublishRelay<URL> = .init()

  private let settingsDataRelay: BehaviorRelay<[[SettingsData]]> = .init(value: [
    [
      // アカウント状況に応じてあとで設定
    ],
    [
      .init(
        section: 1,
        index: 0,
        title: "トイレまっぷを評価する",
        detail: nil,
        image: UIImage(systemSymbol: .starFill),
        type: .evaluate,
        isCustomCell: false
      ),
      .init(
        section: 1,
        index: 1,
        title: "トイレまっぷのレビューを書く",
        detail: nil,
        image: UIImage(systemSymbol: .squareAndPencil),
        type: .writeReview,
        isCustomCell: false
      ),
    ],
    [
      .init(
        section: 2,
        index: 0,
        title: "テーマカラーを変更する",
        detail: nil,
        image: UIImage(systemSymbol: .circleGrid2x2Fill),
        type: .choiceMainColor,
        isCustomCell: false
      )
    ],
    [
      .init(
        section: 3,
        index: 0,
        title: "自宅トイレの設定",
        detail: "自宅のトイレは他の人に表示されることはありません",
        image: UIImage(systemSymbol: .houseFill),
        type: .createHomeToilet,
        isCustomCell: false
      ),
      .init(
        section: 3,
        index: 1,
        title: "プライバシーポリシー",
        detail: "",
        image: UIImage(systemSymbol: .link),
        type: .privacyPolicy,
        isCustomCell: false
      ),
      .init(
        section: 3,
        index: 2,
        title: "利用規約",
        detail: "",
        image: UIImage(systemSymbol: .link),
        type: .termsAndConditions,
        isCustomCell: false
      ),
    ],
  ])

  struct UseCase {
    let signinWithApple = AuthUseCase.SigninWithAppleUseCase()
    let linkCurrentUserWithApple = AuthUseCase.LinkExistingUserWithNewAppleId()
    let observeMe = UserUseCase.ObserveMeUsecase()
    let deleteAuthUser = AuthUseCase.DeleteCurrentUser()
    let signOutAuthUser = AuthUseCase.SignOutCurrentUser()
  }

  private let useCase = UseCase()

  override init() {
    super.init()

    acceptDeleteAccountExecutionRelay
      .flatMap({
        self.useCase.deleteAuthUser
          .execute()
      })
      .bind(to: didCompleteDeleteAccountRelay)
      .disposed(by: disposeBag)

    acceptSignOutExecutionRelay
      .flatMap({
        self.useCase.signOutAuthUser.execute()
      })
      .bind(to: didCompleteSignOutRelay)
      .disposed(by: disposeBag)

    useCase.observeMe.execute().subscribe(onNext: { me in
      var current = self.settingsDataRelay.value
      // アカウントの部分を削除
      current[0].removeAll()

      if let email = me.email, me.status == .signInWithApple {
        let userInfo = SettingsData(
          section: 0,
          index: 0,
          title: "Appleでログイン中",
          detail: "Email: \(email)",
          image: UIImage(systemSymbol: .infoCircle),
          type: .none,
          isCustomCell: false
        )
        let signOut = SettingsData(
          section: 0,
          index: 1,
          title: "",
          detail: nil,
          image: nil,
          type: .none,
          isCustomCell: true
        )
        current[0].append(userInfo)
        current[0].append(signOut)
      } else {
        let signIn = SettingsData(
          section: 0,
          index: 0,
          title: "Continue with Apple",
          detail: "同じAppleIDでログインするとデータを共有できます",
          image: UIImage(named: "signInWithAppleLogo"),
          type: .signInWithAppleLink,
          isCustomCell: true
        )

        current[0].append(signIn)
      }
      self.settingsDataRelay.accept(current)
    })
    .disposed(by: disposeBag)
  }
}

extension SettingsViewModel: SettingsViewModelType {

  var showSignOutConfirmation: Observable<Void> {
    showSignOutConfirmationRelay.asObservable()
  }

  var didCompleteDeleteAccount: Observable<Void> {
    didCompleteDeleteAccountRelay.asObservable()
  }

  var didCompleteSignOut: Observable<Void> {
    didCompleteSignOutRelay.asObservable()
  }

  var errorMessage: Observable<String> {
    errorMessageRelay.asObservable()
  }

  var settingsData: Observable<[[SettingsData]]> {
    settingsDataRelay.asObservable()
  }

  var showColorPicker: Observable<UIColorPickerViewController> {
    showColorPickerRelay.asObservable()
  }

  var showCreateHomeToiletViewController: Observable<Void> {
    showCreateHomeToiletViewContollerRelay.asObservable()
  }

  var showSignInAccountAlreadyLinkedWithAppleIdPrompt: Observable<Void> {
    showSignInAccountAlreadyLinkedWithAppleIdPromptRelay.asObservable()
  }

  var showDeleteAccountConfirmation: Observable<Void> {
    showDeleteAccountConfirmationRelay.asObservable()
  }

  var showPrivacyPolicy: Observable<URL> {
    showPrivacyPolicyRelay.asObservable()
  }

  var showTermsAndCondition: Observable<URL> {
    showTermAndConditionRelay.asObservable()
  }

  func didSelectData(section: Int, index: Int) {
    let data = settingsDataRelay.value[section][index]

    switch data.type {
    case .signInWithAppleLink:
      useCase.linkCurrentUserWithApple
        .execute()
        .catch({ error in
          if let error = error as? AuthRepositoryError,
            case AuthRepositoryError.appleIdHasAlreadyLinkedWithOtherAccount = error
          {
            self.showSignInAccountAlreadyLinkedWithAppleIdPromptRelay.accept(())
            return .never()
          }
          self.errorMessageRelay.accept(error.localizedDescription)
          return .never()
        })
        .bind(to: didCompleteLinkWithAppleID)
        .disposed(by: disposeBag)

    case .delete:
      showDeleteAccountConfirmationRelay.accept(())

    case .signOutAccount:
      showSignOutConfirmationRelay.accept(())

    case .evaluate:
      guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
        let windowScene = appDelegate.window?.windowScene
      else {
        return
      }
      SKStoreReviewController.requestReview(in: windowScene)

    case .writeReview:
      guard
        let writeReviewURL = URL(
          string:
            "https://apps.apple.com/jp/app/%E3%83%88%E3%82%A4%E3%83%AC%E3%81%BE%E3%81%A3%E3%81%B7/id1377935093?action=write-review"
        )
      else {
        assert(false)
        return
      }
      UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)

    case .choiceMainColor:
      let colorPicker = UIColorPickerViewController()
      showColorPickerRelay.accept(colorPicker)

    case .createHomeToilet:
      self.showCreateHomeToiletViewContollerRelay.accept(())

    case .none:
      break
    case .termsAndConditions:
      let url = URL(string: "https://fummicc1.github.io/ToiletMap_Terms_And_Conditions/")!
      showTermAndConditionRelay.accept(url)

    case .privacyPolicy:
      let url = URL(string: "https://fummicc1.github.io/ToiletMap_Privacy_Policy/")!
      showPrivacyPolicyRelay.accept(url)
    }
  }

  func performSignInAccountAlreadyLinkedWithAppleId() {
    useCase.signinWithApple.execute(onAdmitRequest: {})
      .catch({ error in
        #if DEBUG
          print(error)
        #endif
        return .empty()
      })
      .bind(to: didCompleteLinkWithAppleID)
      .disposed(by: disposeBag)
  }

  func didChoiceMainColor(color: UIColor) {
    if color == UIColor.systemBackground {
      return
    }
    Defaults[\.mainColor] = HexColor(hexString: color.hexString)
  }

  func showSignOutConfirmanceAlert() {
    showSignOutConfirmationRelay.accept(())
  }

  func acceptSignOut() {
    acceptSignOutExecutionRelay.accept(())
  }

  func acceptDeleteAccount() {
    acceptDeleteAccountExecutionRelay.accept(())
  }
}
