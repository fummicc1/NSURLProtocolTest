//
//  ToiletDetailViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/06.
//

import Combine
import FirebaseFirestore
import Foundation
import MapKit
import RxCocoa
import RxSwift

protocol ToiletDetailViewModelOutput {

  var routesDetected: Observable<[MKRoute.Step]> { get }
  var routeSteps: [MKRoute.Step] { get }
  var closeDetailView: Observable<MapAnnotation> { get }
  /// index: 今のステップ番号. distance: 現在距離からステップまでの距離（m）
  var currentStepUpdated: Observable<(index: Int, distance: Double)> { get }
  var shouldPresentReviewViewController: Observable<MapAnnotation> { get }
  var reviewScoreObservable: Observable<ReviewScore?> { get }
  var isArchiving: Observable<Bool> { get }
  var isReviewed: Observable<Bool> { get }
  var errorMessage: Observable<String> { get }

  var reviewScorePublisher: AnyPublisher<ReviewScore, Never> { get }

  func didTapRequestRouteButton()
  func didTapArchiveButton()
  func didTapReviewButton()
  func didTapDismissButton()
  func didDeselect(annotation: MKAnnotation)
  func openInDefaultMap()
}

class ToiletDetailViewModel: BaseViewModel, ToiletDetailViewModelOutput {

  private let routeStepsRelay: BehaviorRelay<[MKRoute.Step]> = .init(value: [])
  private let currentStepUpdateRelay: BehaviorRelay<(index: Int, distance: Double)> = .init(
    value: (0, 0))
  private let closeDetailViewRelay: PublishRelay<MapAnnotation> = .init()
  private let reviewScoreRelay: BehaviorRelay<ReviewScore?> = .init(value: nil)
  private let deselectAnnotationRelay: PublishRelay<MKAnnotation> = .init()
  private let shouldPresentReviewViewControllerRelay: PublishRelay<MapAnnotation> = .init()
  private let archiveRefRelay: BehaviorRelay<DocumentReference?> = .init(value: nil)
  private let isReviewedRelay: BehaviorRelay<Bool> = .init(value: false)
  private let errorMessageRelay: PublishRelay<String> = .init()
  private let reviewScoreSubject: CurrentValueSubject<ReviewScore, Never> = .init(
    .init(
      canUse: 0,
      isFree: 0,
      hasWashlet: 0,
      hasAccessibleRestroom: 0,
      alreadyReviewed: false
    )
  )
  private let toilet: ToiletPresentable

  let useCase = UseCase()

  struct UseCase {
    let addLocationMonitoring = LocationUseCase.AddRouteStepRegion()
    let getCurrentLocation = LocationUseCase.GetCurrentLocationUseCase()
    let createArchivedToilet = ArchivedToiletUseCase.CreateArchivedToiletUseCase()
    let deleteArchivedToilet = ArchivedToiletUseCase.DeleteArchivedToiletUseCase()
    let getToiletRoute = ToiletUseCase.GetRoutesUseCase()
    let didEnterRegion = LocationUseCase.ObserveRouteStepRegionEntered()
    let validateIsReviewed = ReviewUseCase.ValidateWhetherUserNotReviewedYetUseCase()
    let calculateReviewScore = ReviewUseCase.CalculateReviewScore()
    let getReviewList = ReviewUseCase.GetReviewListUseCase()
    let observeArchivedToilets: ObserveArchivedToiletsUseCaseType = ArchivedToiletUseCase.ObserveArchivedToiletsUseCase()
    let createToilet: CreateToiletUseCaseType = ToiletUseCase.CreateToiletUseCase()
    let openInDefaultMapUseCase: OpenToiletInDefaultMapUseCase = ToiletUseCase.OpenToiletInDefaultMap()
  }

  var errorMessage: Observable<String> {
    errorMessageRelay.asObservable()
  }

  var closeDetailView: Observable<MapAnnotation> {
    closeDetailViewRelay.asObservable()
  }

  var routeSteps: [MKRoute.Step] {
    routeStepsRelay.value
  }

  var routesDetected: Observable<[MKRoute.Step]> {
    routeStepsRelay.asObservable()
  }

  var currentStepUpdated: Observable<(index: Int, distance: Double)> {
    currentStepUpdateRelay.asObservable()
  }

  var shouldPresentReviewViewController: Observable<MapAnnotation> {
    shouldPresentReviewViewControllerRelay.asObservable()
  }

  var reviewScoreObservable: Observable<ReviewScore?> {
    reviewScoreRelay.asObservable()
  }

  var deselectAnnotation: Observable<MKAnnotation> {
    deselectAnnotationRelay.asObservable()
  }

  var isArchiving: Observable<Bool> {
    archiveRefRelay.map({ $0 != nil })
  }

  var isReviewed: Observable<Bool> {
    isReviewedRelay.asObservable()
  }

  var reviewScorePublisher: AnyPublisher<ReviewScore, Never> {
    reviewScoreSubject.eraseToAnyPublisher()
  }

  var annotation: MapAnnotation

  init?(
    annotation: MapAnnotation
  ) {
    let toilet = annotation.toilet
    self.toilet = toilet

    self.annotation = annotation
    if annotation.isArchived {
      self.archiveRefRelay.accept(toilet.ref)
    }
    super.init()

    let reviews = useCase.getReviewList
      .execute(of: toilet)
      .asObservable()
      .share()

    reviews
      .flatMap({ reviews in
        self.useCase.validateIsReviewed.execute(reviews: reviews)
      })
      .asObservable()
      .map({ !$0 })
      .bind(to: isReviewedRelay)
      .disposed(by: disposeBag)

    reviews
      .flatMap({ reviews in
        self.useCase.calculateReviewScore.execute(reviews: reviews)
      })
      .bind(to: reviewScoreRelay)
      .disposed(by: disposeBag)

    useCase.observeArchivedToilets
      .execute()
      .map { archived in
        archived.first(where: { toilet in
          toilet.latitude == annotation.coordinate.latitude
            && toilet.longitude == annotation.coordinate.longitude
        })
      }
      .map({ $0?.ref })
      .bind(to: archiveRefRelay)
      .disposed(by: disposeBag)

    useCase.didEnterRegion
      .execute()
      .materialize()
      .filter({ $0.element != nil })
      .dematerialize()
      .flatMap({ regionEvent -> Observable<(index: Int, distance: Double)> in
        guard let index = Int(regionEvent.region.identifier) else {
          return .never()
        }
        let nextIndex = index + 1

        if self.routeSteps.count <= nextIndex {
          return .never()
        }

        let nextStep = self.routeSteps[nextIndex]

        guard let currentLocation = try self.useCase.getCurrentLocation.execute() else {
          return .never()
        }

        let currentCoordinate = currentLocation.coordinate
        let nextDistance = currentCoordinate.calculateDistance(with: nextStep.polyline.coordinate)

        return .just((nextIndex, nextDistance))
      })
      .bind(to: currentStepUpdateRelay)
      .disposed(by: disposeBag)

    reviewScoreRelay.subscribe(onNext: { score in
      guard let score = score else {
        return
      }
      self.reviewScoreSubject.send(score)
    })
    .disposed(by: disposeBag)
  }

  func didTapReviewButton() {
    let isReviewed = isReviewedRelay.value
    if isReviewed {
      return
    }

    let toilet = annotation.toilet

    let reviews = useCase.getReviewList
      .execute(of: toilet)
      .asObservable()
      .share()

    reviews
      .flatMap({ reviews in
        self.useCase.validateIsReviewed
          .execute(reviews: reviews)
          .catch({ error in
            if toilet is HomeToiletPresentable {
              return .error(error)
            }
            if case ReviewUseCase.ValidateWhetherUserNotReviewedYetUseCase.Error.toiletIdNotFound =
              error
            {
              return self.useCase.createToilet.execute(presentable: toilet)
                .flatMap({ toilet in
                  self.useCase
                    .validateIsReviewed
                    .execute(
                      reviews: reviews
                    )
                })
            }
            return .error(error)
          })
      })
      .filter({ $0 })
      .map({ _ in
        self.annotation
      })
      .asObservable()
      .bind(to: shouldPresentReviewViewControllerRelay)
      .disposed(by: disposeBag)
  }

  func didTapDismissButton() {
    closeDetailViewRelay.accept(annotation)
  }

  func didDeselect(annotation: MKAnnotation) {
    deselectAnnotationRelay.accept(annotation)
  }

  func didTapArchiveButton() {
    let isArchiving = archiveRefRelay.value != nil

    let toilet = annotation.toilet

    if isArchiving, let archiveRef = archiveRefRelay.value {
      // Delete Archived
      useCase.deleteArchivedToilet
        .execute(archivedId: archiveRef.documentID)
        .catch({ [weak self] error in
          self?.errorMessageRelay.accept(error.localizedDescription)
          return .never()
        })
        .subscribe()
        .disposed(by: disposeBag)
    } else {
      // Create Archived
      useCase.createArchivedToilet
        .execute(from: toilet)
        .catch({ [weak self] error in
          self?.errorMessageRelay.accept(error.localizedDescription)
          return .never()
        })
        .subscribe()
        .disposed(by: disposeBag)
    }
  }

  func didTapRequestRouteButton() {
    let destination = annotation.coordinate

    guard let source = try? useCase.getCurrentLocation.execute() else {
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
      .subscribe(onNext: { steps in
        for index in steps.indices {
          let step = steps[index]
          self.useCase.addLocationMonitoring.execute(
            routeStep: step.polyline.coordinate,
            index: index
          )
        }
        self.routeStepsRelay.accept(steps)
        if let firstStep = steps.first {
          self.currentStepUpdateRelay.accept((0, firstStep.distance))
        }
      })
      .disposed(by: disposeBag)
  }

  func openInDefaultMap() {
    useCase.openInDefaultMapUseCase.execute(toilet: toilet)
  }
}
