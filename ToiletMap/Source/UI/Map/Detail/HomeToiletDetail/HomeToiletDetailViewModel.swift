//
//  HomeToiletDetailViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/05/26.
//

import FirebaseFirestore
import Foundation
import MapKit
import RxCocoa
import RxSwift

protocol HomeToiletDetailViewModelOutput {

  var routesDetected: Observable<[MKRoute.Step]> { get }
  var routeSteps: [MKRoute.Step] { get }
  var closeDetailView: Observable<MapAnnotation> { get }
  /// index: 今のステップ番号. distance: 現在距離からステップまでの距離（m）
  var currentStepUpdated: Observable<(index: Int, distance: Double)> { get }
  var errorMessage: Observable<String> { get }

  func didTapRequestRouteButton()
  func didTapDismissButton()
  func didDeselect(annotation: MKAnnotation)
}

class HomeToiletDetailViewModel: BaseViewModel, HomeToiletDetailViewModelOutput {

  private let routeStepsRelay: BehaviorRelay<[MKRoute.Step]> = .init(value: [])
  private let currentStepUpdateRelay: BehaviorRelay<(index: Int, distance: Double)> = .init(
    value: (0, 0))
  private let closeDetailViewRelay: PublishRelay<MapAnnotation> = .init()
  private let deselectAnnotationRelay: PublishRelay<MKAnnotation> = .init()
  private let errorMessageRelay: PublishRelay<String> = .init()

  let useCase = UseCase()

  struct UseCase {
    let getCurrentLocation = LocationUseCase.GetCurrentLocationUseCase()
    let getToiletRoute = ToiletUseCase.GetRoutesUseCase()
    let didEnterRegion = LocationUseCase.ObserveRouteStepRegionEntered()
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

  var deselectAnnotation: Observable<MKAnnotation> {
    deselectAnnotationRelay.asObservable()
  }

  var annotation: MapAnnotation

  init?(
    annotation: MapAnnotation
  ) {
    self.annotation = annotation
    super.init()

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
  }

  func didTapDismissButton() {
    closeDetailViewRelay.accept(annotation)
  }

  func didDeselect(annotation: MKAnnotation) {
    deselectAnnotationRelay.accept(annotation)
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
      .bind(to: routeStepsRelay)
      .disposed(by: disposeBag)

    steps.compactMap({ steps in
      steps.first
    })
    .map({ step in
      (index: 0, distance: step.distance)
    })
    .bind(to: currentStepUpdateRelay)
    .disposed(by: disposeBag)
  }
}
