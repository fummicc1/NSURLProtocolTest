//
//  ReviewToiletListViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/17.
//

import Foundation
import RxRelay
import RxSwift

protocol ReviewToiletListViewModelType: AnyObject {
  var reviewToiletList: Observable<[ToiletPresentable]> { get }
  var reviews: Observable<[ReviewPresentable]> { get }
}

class ReviewToiletListViewModel: BaseViewModel, ReviewToiletListViewModelType {
  private let reviewsRelay: BehaviorRelay<[ReviewPresentable]> = .init(value: [])

  struct UseCase {
    let observeReviewList = ReviewUseCase.ObserveReviewListUseCase()
    let observeMe = UserUseCase.ObserveMeUsecase()
  }

  private let useCase = UseCase()

  override init() {
    super.init()

    useCase
      .observeMe
      .execute()
      .asObservable()
      .flatMap({ me in
        self.useCase
          .observeReviewList
          .execute(of: me)
      })
      .catchAndReturn(reviewsRelay.value)
      .bind(to: reviewsRelay)
      .disposed(by: disposeBag)
  }
}

extension ReviewToiletListViewModel {
  var reviewToiletList: Observable<[ToiletPresentable]> {
    reviewsRelay.map({
      $0.compactMap({ review in review.toilet })
    })
  }

  var reviews: Observable<[ReviewPresentable]> {
    reviewsRelay.asObservable()
  }
}
