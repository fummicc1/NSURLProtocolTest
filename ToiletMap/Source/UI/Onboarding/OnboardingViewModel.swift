//
//  OnboardingViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/07/26.
//

import AuthenticationServices
import Foundation
import RxRelay
import RxSwift

protocol OnboardingViewModelType {

  var isLoading: Observable<Bool> { get }
  var moveToHomeViewController: Observable<Void> { get }
  var showTermsOfServiceViewController: Observable<Bool> { get }
  var acceptedTermsOfService: Observable<Bool> { get }

  func didTapAppleButton()
  func didTapGuestButton()
  func didTapToggleTermsOfServiceStatusButton()
  func didTapShowTermsOfServiceButton()
}

class OnboardingViewModel: BaseViewModel, OnboardingViewModelType {

  private let isLoadingRelay: BehaviorRelay<Bool> = .init(value: false)
  private let moveToHomeViewControllerRelay: PublishRelay<Void> = .init()
  private let showTermsOfServiceViewControllerRelay: PublishRelay<Bool> = .init()
  private let acceptedTermsOfServiceRelay: BehaviorRelay<Bool> = .init(value: false)

  private let useCase: UseCase = UseCase()

  struct UseCase {
    let signInWithApple = AuthUseCase.SigninWithAppleUseCase()
    let signInAsGuest = AuthUseCase.SignInAsGuestUseCase()
  }
}

extension OnboardingViewModel {

  var isLoading: Observable<Bool> {
    isLoadingRelay.asObservable()
  }

  var moveToHomeViewController: Observable<Void> {
    moveToHomeViewControllerRelay.asObservable()
  }

  var showTermsOfServiceViewController: Observable<Bool> {
    showTermsOfServiceViewControllerRelay.asObservable()
  }

  var acceptedTermsOfService: Observable<Bool> {
    acceptedTermsOfServiceRelay.asObservable()
  }

  func didTapAppleButton() {
    useCase.signInWithApple
      .execute(onAdmitRequest: {
        self.isLoadingRelay.accept(true)
      })
      .materialize()
      .do(onNext: { [weak self] event in
        self?.isLoadingRelay.accept(false)
      })
      .dematerialize()
      .bind(to: moveToHomeViewControllerRelay)
      .disposed(by: disposeBag)
  }

  func didTapGuestButton() {
    isLoadingRelay.accept(true)
    useCase.signInAsGuest
      .execute()
      .materialize()
      .do(onNext: { _ in
        self.isLoadingRelay.accept(false)
      })
      .dematerialize()
      .bind(to: moveToHomeViewControllerRelay)
      .disposed(by: disposeBag)
  }

  func didTapToggleTermsOfServiceStatusButton() {
    let new = acceptedTermsOfServiceRelay.value.reverse()
    acceptedTermsOfServiceRelay.accept(new)

    let prefs = UserDefaults.standard
    prefs.set(new, forKey: "is_accepted_rules")
  }

  func didTapShowTermsOfServiceButton() {
    showTermsOfServiceViewControllerRelay.accept(true)
  }
}
