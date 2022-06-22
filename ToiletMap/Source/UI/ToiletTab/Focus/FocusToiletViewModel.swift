//
//  FocusToiletViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/18.
//

import CoreLocation
import Foundation
import MapKit
import RxRelay
import RxSwift

protocol FocusToiletViewModelType {
  var errorMessage: Observable<String> { get }
  var toiletMapAnnotation: Observable<MapAnnotation> { get }
  var currentStep: Observable<(index: Int, distance: Double?)> { get }
  var steps: Observable<[MKRoute.Step]> { get }

  func didTapRouteButton()
}

class FocusToiletViewModel: BaseViewModel, FocusToiletViewModelType {

  struct UseCase {
    let getToilet = ToiletUseCase.GetToiletUseCase()
    let currentLocation = LocationUseCase.GetCurrentLocationUseCase()
    let getToiletRoute = ToiletUseCase.GetRoutesUseCase()
  }

  private let useCase = UseCase()

  private let toiletRelay: BehaviorRelay<ToiletPresentable?>
  private let annotationRelay: BehaviorRelay<MapAnnotation?> = .init(value: nil)
  private let routeStepsRelay: BehaviorRelay<[MKRoute.Step]> = .init(value: [])
  private let currentStepRelay: BehaviorRelay<(index: Int, distance: Double?)> = .init(
    value: (0, nil))
  private let errorMessageRelay: PublishRelay<String> = .init()

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

  init(toilet: ToiletPresentable) {
    toiletRelay = .init(value: toilet)

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
}
