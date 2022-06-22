//
//  ReviewViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/02/09.
//

import Foundation
import RxRelay
import RxSwift

protocol ReviewViewModelType {
  var errorMessage: Observable<String> { get }
  var completeSendingReview: Observable<Void> { get }
  var canUse: Observable<Bool> { get }
  var isFree: Observable<Bool> { get }
  var hasWashlet: Observable<Bool> { get }
  var hasAccessibleRestroom: Observable<Bool> { get }
  func sendReview()
  init(storableToilet: MapAnnotation)

  func updateField(field: ReviewViewModel.ReviewField, value: Bool)
}

class ReviewViewModel: BaseViewModel, ReviewViewModelType {

  enum ReviewField {
    case canUse
    case isFree
    case hasWashlet
    case hasAcccessibleRestroom
  }

  var canUse: Observable<Bool> {
    canUseRelay.asObservable()
  }

  var isFree: Observable<Bool> {
    isFreeRelay.asObservable()
  }

  var hasWashlet: Observable<Bool> {
    hasWashletRelay.asObservable()
  }

  var hasAccessibleRestroom: Observable<Bool> {
    hasAccessibleRestroomRelay.asObservable()
  }

  var errorMessage: Observable<String> {
    errorMessageRelay.asObservable()
  }
  var completeSendingReview: Observable<Void> {
    completeSendingReviewRelay.asObservable()
  }

  private let canUseRelay: BehaviorRelay<Bool> = .init(value: false)
  private let isFreeRelay: BehaviorRelay<Bool> = .init(value: false)
  private let hasWashletRelay: BehaviorRelay<Bool> = .init(value: false)
  private let hasAccessibleRestroomRelay: BehaviorRelay<Bool> = .init(value: false)
  private let targetToiletRelay: BehaviorRelay<MapAnnotation>
  private let completeSendingReviewRelay: PublishRelay<Void> = .init()

  private let errorMessageRelay: PublishRelay<String> = .init()

  private let useCase: UseCase = UseCase()

  struct UseCase {
    let createReviewUseCase = ReviewUseCase.CreateReviewUseCase()
  }

  required init(storableToilet: MapAnnotation) {
    targetToiletRelay = .init(value: storableToilet)
    super.init()
  }

  func sendReview() {

    let toilet = targetToiletRelay.value.toilet

    useCase.createReviewUseCase
      .execute(
        toilet: toilet,
        canUse: canUseRelay.value,
        isFree: isFreeRelay.value,
        hasWashlet: hasWashletRelay.value,
        hasAccessibleRestroom: hasAccessibleRestroomRelay.value
      )
      .catch({ [weak self] error in
        self?.errorMessageRelay.accept(error.localizedDescription)
        return .never()
      })
      .subscribe(onSuccess: { [weak self] in
        self?.completeSendingReviewRelay.accept(())
      })
      .disposed(by: disposeBag)
  }

  func updateField(field: ReviewField, value: Bool) {
    switch field {
    case .canUse:
      canUseRelay.accept(value)

    case .hasWashlet:
      hasWashletRelay.accept(value)

    case .hasAcccessibleRestroom:
      hasAccessibleRestroomRelay.accept(value)

    case .isFree:
      isFreeRelay.accept(value)
    }
  }
}
