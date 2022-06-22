//
//  CreateToiletDiaryViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/08/03.
//

import CoreLocation
import Foundation
import RxRelay
import RxSwift

struct CreateToiletDiaryInputModel {
  let type: ToiletDiaryType
  let memo: String
  let date: Date
}

protocol CreateToiletDiaryViewModelType {

  var errorMessage: Observable<String> { get }
  var memo: Observable<String> { get }
  var date: Observable<Date> { get }
  var diaryType: Observable<ToiletDiaryType> { get }
  var completeRecordingToiletDiary: Observable<Void> { get }

  func update(memo: String)
  func update(date: Date)
  func update(type: ToiletDiaryType)

  func save()
}

class CreateToiletDiaryViewModel: BaseViewModel {

  private let errorRelay: PublishRelay<Error> = .init()
  private let memoRelay: BehaviorRelay<String> = .init(value: "")
  private let dateRelay: BehaviorRelay<Date> = .init(value: Date())
  private let diaryTypeRelay: BehaviorRelay<ToiletDiaryType> = .init(value: .pee)
  private let completeRecordingToiletDiaryRelay: PublishRelay<Void> = .init()

  private let dependency: Dependency
  private let location: CLLocationCoordinate2D

  init(
    dependency: CreateToiletDiaryViewModel.Dependency,
    location: CLLocationCoordinate2D
  ) {
    self.dependency = dependency
    self.location = location
    super.init()
  }

}

extension CreateToiletDiaryViewModel {
  struct Dependency {
    let createToiletDiaryUseCase: RecordToiletDiaryUseCase
    let updateToiletDiaryUseCase: EditRecordedToiletDiaryUseCase
    let deleteToiletDiaryUseCase: DeleteToiletDiaryUseCase
  }

  enum Error: Swift.Error {
    case futureDate
    case underlying(Swift.Error)
  }
}

extension CreateToiletDiaryViewModel: CreateToiletDiaryViewModelType {

  var completeRecordingToiletDiary: Observable<Void> {
    completeRecordingToiletDiaryRelay.asObservable()
  }

  var errorMessage: Observable<String> {
    errorRelay.map({ $0.localizedDescription })
  }

  var memo: Observable<String> {
    memoRelay.asObservable()
  }

  var date: Observable<Date> {
    dateRelay.asObservable()
  }

  var diaryType: Observable<ToiletDiaryType> {
    diaryTypeRelay.asObservable()
  }

  func update(date: Date) {
    dateRelay.accept(date)
  }

  func update(memo: String) {
    memoRelay.accept(memo)
  }

  func update(type: ToiletDiaryType) {
    diaryTypeRelay.accept(type)
  }

  func save() {

    let input = RecordUseToiletInput(
      date: dateRelay.value,
      memo: memoRelay.value,
      type: diaryTypeRelay.value,
      latitude: location.latitude,
      longitude: location.longitude
    )

    dependency.createToiletDiaryUseCase.execute(input: input)
      .subscribe(
        onNext: {
          self.completeRecordingToiletDiaryRelay.accept(())
        },
        onError: { error in
          self.errorRelay.accept(.underlying(error))
        }
      )
      .disposed(by: disposeBag)
  }
}
