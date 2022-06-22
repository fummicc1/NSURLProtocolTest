//
//  CreateHomeToiletViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/05/26.
//

import CoreLocation
import Foundation
import RxRelay
import RxSwift

protocol CreateHomeToiletViewModelType {
  var location: Observable<CLLocationCoordinate2D> { get }
  var oldHomeToilet: Observable<HomeToiletPresentable> { get }
  var error: Observable<Error> { get }
  var completeUpdating: Observable<Void> { get }

  func determine()
  func changeLocation(_ coordinate: CLLocationCoordinate2D)
}

class CreateHomeToiletViewModel: BaseViewModel, CreateHomeToiletViewModelType {
  private let locationRelay: BehaviorRelay<CLLocationCoordinate2D?> = .init(value: nil)
  private let errorRelay: PublishRelay<Swift.Error> = .init()

  private let oldHomeToiletRelay: BehaviorRelay<HomeToiletPresentable?> = .init(value: nil)
  private let completeUpdatingRelay: PublishRelay<Void> = .init()

  private let usecase = Usecase()

  struct Usecase {
    let fetchMe: UserUseCase.GetMeUseCase = .init()
    let getHomeToilet: HomeToiletUsecase.GetHomeToilet = .init()
    let createHomeToilet: HomeToiletUsecase.CreateHomeToilet = .init()
    let updateHomeToilet: HomeToiletUsecase.UpdateHomeToilet = .init()
  }

  init(oldHomeToilet: HomeToiletPresentable? = nil) {
    self.oldHomeToiletRelay.accept(oldHomeToilet)
    super.init()

    usecase.getHomeToilet
      .execute()
      .asObservable()
      .bind(to: oldHomeToiletRelay)
      .disposed(by: disposeBag)
  }
}

extension CreateHomeToiletViewModel {

  enum Error: Swift.Error {
    case locationIsNotSelected
  }

  var location: Observable<CLLocationCoordinate2D> {
    locationRelay.compactMap({ $0 })
  }

  var error: Observable<Swift.Error> {
    errorRelay.asObservable()
  }

  var oldHomeToilet: Observable<HomeToiletPresentable> {
    oldHomeToiletRelay.compactMap({ $0 })
  }

  var completeUpdating: Observable<Void> {
    completeUpdatingRelay.asObservable()
  }

  func determine() {
    usecase.fetchMe.execute()
      .flatMap({ me -> Single<Void> in
        guard let location = self.locationRelay.value else {
          return .error(Error.locationIsNotSelected)
        }
        var homeToilet = HomeToiletFragment(
          sender: me,
          name: "自宅トイレ",
          detail: nil,
          latitude: location.latitude,
          longitude: location.longitude,
          ref: nil,
          createdAt: nil,
          updatedAt: nil
        )

        if let oldHomeToilet = self.oldHomeToiletRelay.value {
          homeToilet.ref = oldHomeToilet.ref
          homeToilet.createdAt = oldHomeToilet.createdAt
          return self.usecase.updateHomeToilet.execute(homeToilet: homeToilet)
        }
        return self.usecase.createHomeToilet.execute(homeToilet: homeToilet)
      })
      .catch({ error in
        self.errorRelay.accept(error)
        return .never()
      })
      .subscribe(onSuccess: { [weak self] in
        self?.completeUpdatingRelay.accept(())
      })
      .disposed(by: disposeBag)
  }

  func changeLocation(_ coordinate: CLLocationCoordinate2D) {
    locationRelay.accept(coordinate)
  }
}
