//
//  ToiletMapViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/01.
//

import FirebaseFirestore
import Foundation
import MapKit
import RxCocoa
import RxSwift

protocol ToiletMapViewModelOutput {

  var errorMessage: Observable<String> { get }

  /// マップに表示するアノテーションの配列
  var toiletMapAnnotations: Observable<[MapAnnotation]> { get }

  var toiletMapAnnotationsValue: [MapAnnotation] { get }

  var homeToiletAnnotation: Observable<HomeToiletAnnotation?> { get }
}

typealias ToiletMapViewModel = ToiletMapViewModelOutput

final class ToiletMapViewModelImpl: BaseViewModel, ToiletMapViewModel {

  // MARK: - Output
  var toiletMapAnnotations: Observable<[MapAnnotation]> {
    toiletMapAnnotationsRelay
      .debounce(.milliseconds(1), scheduler: MainScheduler.instance)
  }
  var toiletMapAnnotationsValue: [MapAnnotation] {
    toiletMapAnnotationsRelay.value
  }

  var isLocationAuthorized: Observable<Bool> {
    useCase
      .observeLocationAuthorizationStatus
      .execute()
      .share()
      .map({ status in
        self.isAuthorized(status: status)
      })
  }

  var errorMessage: Observable<String> {
    errorMessageRelay.asObservable()
  }

  var homeToiletAnnotation: Observable<HomeToiletAnnotation?> {
    homeToiletAnnotationRelay.asObservable()
  }

  private let homeToiletAnnotationRelay: BehaviorRelay<HomeToiletAnnotation?> = .init(value: nil)
  private let toiletMapAnnotationsRelay: BehaviorRelay<[MapAnnotation]> = .init(value: [])
  private let errorMessageRelay: PublishRelay<String> = .init()

  // MARK: - Dependency
  private let useCase: UseCase = .init()

  struct UseCase {
    let currentLocation = LocationUseCase.GetCurrentLocationUseCase()
    let observeLocationAuthorizationStatus = LocationUseCase.ObserveAuthorizationStatusUseCase()
    let requestLocationAuthorization = LocationUseCase.RequestAuthorizationUseCase()
    let observeLocation = LocationUseCase.ObserveCurrentLocationUseCase()
    let toilets = ToiletUseCase.ObserveAllToiletUseCase()
    let archivedToilets = ArchivedToiletUseCase.ObserveArchivedToiletsUseCase()
    let annotations = MapItemUseCase.ObserveCurrentMapItemUseCase()
    let observeHomeToilet = HomeToiletUsecase.ObserveHomeToilet()
  }

  // MARK: - Initialize
  override init() {
    super.init()

    isLocationAuthorized.filter({ !$0 })
      .subscribe(onNext: { _ in
        self.useCase.requestLocationAuthorization
          .execute(isFullAccuracy: false, purposeKey: nil)
      })
      .disposed(by: disposeBag)

    useCase
      .observeLocation
      .execute()
      .debounce(.seconds(1), scheduler: MainScheduler.instance)
      .take(1)
      .flatMap({ [weak self] location -> Observable<[MapAnnotation]> in
        guard let self = self else {
          return .empty()
        }
        return
          Observable
          .combineLatest(
            self.useCase.toilets.execute(),
            self.useCase.archivedToilets.execute(),
            self.useCase.annotations.execute()
          )
          .map({ toilets, archivedToilets, mapItems in
            self.filterAnnotations(toilets: toilets, archived: archivedToilets, search: mapItems)
          })
      })
      .bind(to: self.toiletMapAnnotationsRelay)
      .disposed(by: self.disposeBag)

    useCase.observeHomeToilet.execute()
      .subscribe(onNext: { [weak self] homeToilet in
        let distance: Double?
        if let currentPlace = LocationShared.default.locationManager.location?.coordinate {
          let location = CLLocationCoordinate2D(
            latitude: homeToilet.latitude, longitude: homeToilet.longitude)
          distance = location.calculateDistance(with: currentPlace)
        } else {
          distance = nil
        }
        let annotation = HomeToiletAnnotation(toilet: homeToilet, distance: distance)
        self?.homeToiletAnnotationRelay.accept(annotation)
      })
      .disposed(by: disposeBag)
  }

  // MARK: - Method

  private func filterAnnotations(
    toilets: [ToiletPresentable],
    archived: [ArchivedToiletPresentable],
    search: [MapAnnotation]
  ) -> [MapAnnotation] {

    let uniqueToilets =
      toilets
      .filter({ toilet in
        search
          .map({ $0.coordinate })
          .doesNotContain(
            CLLocationCoordinate2D(
              latitude: toilet.latitude,
              longitude: toilet.longitude
            )
          )
      })
      .filter({ toilet in
        archived
          .map({ CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) })
          .doesNotContain(
            CLLocationCoordinate2D(
              latitude: toilet.latitude,
              longitude: toilet.longitude
            )
          )
      })
      .map({ toilet -> ToiletMapAnnotation in
        let distance: Double?
        if let location = try? self.useCase.currentLocation.execute() {
          distance = location.coordinate
            .calculateDistance(
              with: CLLocationCoordinate2D(
                latitude: toilet.latitude,
                longitude: toilet.longitude
              )
            )
        } else {
          distance = nil
        }
        return ToiletMapAnnotation(
          toilet: toilet,
          distance: distance
        )
      })
    let searchAnnotations =
      search
      .filter({ item in
        archived.map({ archived in
          CLLocationCoordinate2D(
            latitude: archived.latitude,
            longitude: archived.longitude
          )
        })
        .doesNotContain(item.coordinate)
      })
      .compactMap({ item in
        item as? iOSMapAnnotation
      })
    let archivedAnnotation =
      archived
      .map({ archived -> ToiletMapAnnotation in
        let distance: Double?
        if let coordinate = try? self.useCase.currentLocation.execute()?.coordinate {
          distance =
            coordinate
            .calculateDistance(
              with: CLLocationCoordinate2D(
                latitude: archived.latitude,
                longitude: archived.longitude
              )
            )
        } else {
          distance = nil
        }
        return ToiletMapAnnotation(
          toilet: archived,
          distance: distance
        )
      })

    return archivedAnnotation + uniqueToilets + searchAnnotations
  }

  private func isAuthorized(status: CLAuthorizationStatus) -> Bool {
    status.rawValue == 3 || status.rawValue == 4
  }
}
