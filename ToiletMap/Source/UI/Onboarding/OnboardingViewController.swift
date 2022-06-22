//
//  OnboardingViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/07/26.
//

import AuthenticationServices
import Foundation
import NVActivityIndicatorView
import UIKit
import WebKit

class OnboardingViewController: BaseViewController {

  private let viewModel: OnboardingViewModelType = OnboardingViewModel()

  @IBOutlet private weak var accountStackView: UIStackView!
  @IBOutlet private weak var signInAsGuestButton: UIButton!
  @IBOutlet private weak var checkTermsOfServiceButton: UIButton!
  @IBOutlet private weak var webView: WKWebView!

  private weak var activityIndicator: NVActivityIndicatorView?

  private static let imageConfiguration = UIImage.SymbolConfiguration(
    pointSize: 24, weight: .medium)

  private lazy var signInWithAppleButton = ASAuthorizationAppleIDButton(
    authorizationButtonType: .signIn,
    authorizationButtonStyle: traitCollection.userInterfaceStyle == .dark ? .white : .black
  )

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.title = "Welcome"

    if let url = URL(string: "https://fummicc1.github.io/ToiletMap_Terms_And_Conditions/") {
      webView.load(URLRequest(url: url))
    }

    let guestButtonAction: UIAction = UIAction { _ in
      self.viewModel.didTapGuestButton()
    }

    let appleButtonAction = UIAction { _ in
      self.viewModel.didTapAppleButton()
    }

    signInAsGuestButton.addAction(guestButtonAction, for: .touchUpInside)
    signInWithAppleButton.addAction(appleButtonAction, for: .touchUpInside)

    accountStackView.insertArrangedSubview(signInWithAppleButton, at: 0)

    checkTermsOfServiceButton.rx.tap
      .subscribe(onNext: { [weak self] in
        self?.viewModel.didTapToggleTermsOfServiceStatusButton()
      })
      .disposed(by: disposeBag)

    viewModel.acceptedTermsOfService
      .subscribe(onNext: { [weak self] accepted in
        let image: UIImage
        if accepted {
          image = UIImage(
            systemSymbol: .checkmarkSquare,
            withConfiguration: Self.imageConfiguration
          )

        } else {
          image = UIImage(
            systemSymbol: .square,
            withConfiguration: Self.imageConfiguration
          )
        }
        self?.checkTermsOfServiceButton.setImage(image, for: .normal)
      })
      .disposed(by: disposeBag)

    viewModel.isLoading.subscribe(onNext: { [weak self] isLoading in
      if isLoading {
        self?.activityIndicator?.startAnimating()
      } else {
        self?.activityIndicator?.stopAnimating()
      }
    })
    .disposed(by: disposeBag)

    viewModel.moveToHomeViewController
      .subscribe(onNext: {
        guard let window = UIApplication.shared.delegate?.window as? UIWindow else {
          assert(false)
          return
        }
        window.rootViewController = TabBarController(showTutorial: false)
        window.makeKeyAndVisible()
      })
      .disposed(by: disposeBag)

    viewModel.acceptedTermsOfService
      .bind(to: signInAsGuestButton.rx.isEnabled)
      .disposed(by: disposeBag)

    viewModel.acceptedTermsOfService
      .bind(to: signInWithAppleButton.rx.isEnabled)
      .disposed(by: disposeBag)

    viewModel.acceptedTermsOfService
      .subscribe(onNext: { [weak self] accepted in
        let color = accepted ? AppColor.textColor : AppColor.errorColor
        self?.checkTermsOfServiceButton.setTitleColor(color, for: .normal)
      })
      .disposed(by: disposeBag)

    // MARK: Setup View
    let activityIndicator = NVActivityIndicatorView(
      frame: CGRect(
        origin: .zero,
        size: .init(width: 56, height: 56)
      ),
      type: .ballScaleRippleMultiple,
      color: AppColor.mainColor
    )
    DispatchQueue.main.async {
      activityIndicator.center = self.view.center
    }
    view.addSubview(activityIndicator)
    self.activityIndicator = activityIndicator
  }

}
