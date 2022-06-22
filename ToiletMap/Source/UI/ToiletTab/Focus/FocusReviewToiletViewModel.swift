//
//  FocusReviewToiletViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/07/13.
//

import Foundation
import MapKit
import RxRelay
import RxSwift

protocol FocusReviewToiletViewModelType: FocusToiletViewModelType {

  var toilet: ToiletPresentable { get }
  var review: ReviewPresentable { get }

  var closeEditReviewView: Observable<Void> { get }
  func commitReviewChange(review: ReviewPresentable)
}

class FocusReviewToiletViewModel: BaseViewModel, FocusReviewToiletViewModelType {

  struct UseCase {
    let getToilet = ToiletUseCase.GetToiletUseCase()
    let currentLocation = LocationUseCase.GetCurrentLocationUseCase()
    let getToiletRoute = ToiletUseCase.GetRoutesUseCase()
    let updateReview = ReviewUseCase.UpdateReviewUsecase()
  }

  private let useCase = UseCase()

  private let toiletRelay: BehaviorRelay<ToiletPresentable>
  private let reviewRelay: BehaviorRelay<ReviewPresentable>
  private let annotationRelay: BehaviorRelay<MapAnnotation?> = .init(value: nil)
  private let routeStepsRelay: BehaviorRelay<[MKRoute.Step]> = .init(value: [])
  private let currentStepRelay: BehaviorRelay<(index: Int, distance: Double?)> = .init(
    value: (0, nil))
  private let errorMessageRelay: PublishRelay<String> = .init()
  private let closeEditReviewViewRelay: PublishRelay<Void> = .init()

  var toilet: ToiletPresentable {
    toiletRelay.value
  }

  var review: ReviewPresentable {
    reviewRelay.value
  }

  var closeEditReviewView: Observable<Void> {
    closeEditReviewViewRelay.asObservable()
  }

  var errorMessage: Observable<String> {
    errorMessageRelay.asObservable()
  }

  var toiletMapAnnotation: Observable<MapAnnotation> {
    annotationRelay.compactMap({ $0 })
  }

  var currentStep: Observable<(index: Int, distance: Double?)> {
    currentStepRelay.asObservable()
  }

  var steps: Observable<[MKRoute.Step]> {
    routeStepsRelay.asObservable()
  }

  init(toilet: ToiletPresentable, review: ReviewPresentable) {
    toiletRelay = .init(value: toilet)
    reviewRelay = .init(value: review)

    super.init()

    if let toiletId = toilet.ref?.documentID {
      useCase.getToilet
        .execute(id: toiletId)
        .asObservable()
        .bind(to: toiletRelay)
        .disposed(by: disposeBag)
    }

    toiletRelay
      .compactMap({ $0 })
      .compactMap({ toilet in
        guard let current = try self.useCase.currentLocation.execute() else {
          return nil
        }
        let toiletCoordinate = CLLocationCoordinate2D(
          latitude: toilet.latitude,
          longitude: toilet.longitude
        )
        let distance = current.coordinate.calculateDistance(with: toiletCoordinate)
        return ToiletMapAnnotation(toilet: toilet, distance: distance)
      })
      .bind(to: annotationRelay)
      .disposed(by: disposeBag)
  }

  func didTapRouteButton() {
    guard let annotation = annotationRelay.value else {
      return
    }
    let destination = annotation.coordinate

    guard let source = try? useCase.currentLocation.execute() else {
      return
    }

    let steps = useCase.getToiletRoute
      .execute(from: source.coordinate, to: destination)
      .compactMap({ routes in
        routes.first
      })
      .map({ route in
        route.steps
      })
      .asObservable()
      .share()

    steps
      .bind(to: routeStepsRelay)
      .disposed(by: disposeBag)

    steps.compactMap({ steps in
      steps.first
    })
    .map({ step in
      (index: 0, distance: step.distance)
    })
    .bind(to: currentStepRelay)
    .disposed(by: disposeBag)
  }

  func commitReviewChange(review: ReviewPresentable) {
    let toilet = toiletRelay.value
    reviewRelay.accept(review)
    useCase.updateReview
      .execute(toilet: toilet, review: review)
      .catch({ error in
        self.errorMessageRelay.accept(error.localizedDescription)
        return .never()
      })
      .bind(to: closeEditReviewViewRelay)
      .disposed(by: disposeBag)
  }

}
