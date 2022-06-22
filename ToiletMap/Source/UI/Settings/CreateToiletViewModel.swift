//
//  CreateToiletViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/02/09.
//

import CoreLocation
import Foundation
import MapKit
import RxRelay
import RxSwift

protocol CreateToiletViewModelType {
  var isOnSwitch: Observable<Bool> { get }
  var currentUserLocation: Observable<CLLocation?> { get }
  var errorMessage: Observable<String> { get }
  func update(name: String)
  func update(detail: String)
  func changeLocation(coordinate: CLLocationCoordinate2D)
  func create() -> Single<Void>
  func getMapRegion() -> MKCoordinateRegion?
  func updateIsOnSwitch(isOn: Bool)
}

enum CreateToiletViewModelError: Error {
  case noName
}

class CreateToiletViewModel: BaseViewModel, CreateToiletViewModelType {

  private let isOnSwitchRelay: BehaviorRelay<Bool> = .init(value: false)
  private let currentUserLocationRelay: BehaviorRelay<CLLocation?> = .init(value: nil)
  private let addLocationRelay: BehaviorRelay<CLLocationCoordinate2D?> = .init(value: nil)
  private let detailRelay: BehaviorRelay<String> = .init(value: "")
  private let nameRelay: BehaviorRelay<String> = .init(value: "")
  private let errorMessageRelay: PublishRelay<String> = .init()

  var currentUserLocation: Observable<CLLocation?> {
    currentUserLocationRelay.asObservable()
  }

  var isOnSwitch: Observable<Bool> {
    isOnSwitchRelay.asObservable()
  }

  var errorMessage: Observable<String> {
    errorMessageRelay.asObservable().distinctUntilChanged()
  }

  let useCase: UseCase = .init()

  struct UseCase {
    let observeCurrentLocation = LocationUseCase.ObserveCurrentLocationUseCase()
    let createToiletUseCase = ToiletUseCase.CreateToiletUseCase()
  }

  override init() {
    super.init()
    useCase.observeCurrentLocation
      .execute()
      .bind(to: currentUserLocationRelay)
      .disposed(by: disposeBag)
  }

  func getMapRegion() -> MKCoordinateRegion? {
    guard let location = getCurrentUserLocation() else {
      return nil
    }
    return MKCoordinateRegion(
      center: location.coordinate,
      latitudinalMeters: 200,
      longitudinalMeters: 200
    )
  }

  private func getCurrentUserLocation() -> CLLocation? {
    currentUserLocationRelay.value
  }

  func updateIsOnSwitch(isOn: Bool) {
    isOnSwitchRelay.accept(isOn)
  }

  func update(detail: String) {
    detailRelay.accept(detail)
  }

  func changeLocation(coordinate: CLLocationCoordinate2D) {
    addLocationRelay.accept(coordinate)
  }

  func create() -> Single<Void> {
    Single<
      (
        name: String,
        detail: String?,
        location: CLLocationCoordinate2D
      )
    >
    .create { [weak self] (singleEvent) -> Disposable in
      guard let self = self else {
        return Disposables.create()
      }
      let detail = self.detailRelay.value
      let name = self.nameRelay.value

      if name.isEmpty {
        self.errorMessageRelay.accept("名前が入力されていません")
        return Disposables.create()
      }

      let isOn = self.isOnSwitchRelay.value
      let addLocation: CLLocationCoordinate2D
      if isOn {
        guard let currentUserLocation = self.currentUserLocationRelay.value?.coordinate else {
          return Disposables.create()
        }
        addLocation = currentUserLocation
      } else if let _addLocation = self.addLocationRelay.value {
        addLocation = _addLocation
      } else {
        return Disposables.create()
      }
      singleEvent(.success((name, detail, addLocation)))
      return Disposables.create()
    }
    .flatMap({ name, detail, location in
      self.useCase.createToiletUseCase.execute(
        name: name,
        detail: detail,
        location: location
      )
      .map({ _ in () })
    })
    .catch { [weak self] error in
      self?.errorMessageRelay.accept(error.localizedDescription)
      return .never()
    }
  }

  func update(name: String) {
    nameRelay.accept(name)
  }
}
