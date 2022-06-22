//
//  EditToiletDiaryViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/08/16.
//

import Foundation
import RxRelay
import RxSwift

struct EditToiletDiaryDTO {
  var memo: String
  var date: Date
  var type: ToiletDiaryType

  mutating func update<V>(keyPath: WritableKeyPath<Self, V>, valie: V) {
    self[keyPath: keyPath] = valie
  }
}

struct EditToiletDiaryInitializeParameter {
  let toiletDiary: ToiletDiaryPresentable
}

protocol EditToiletDiaryViewModelType {

  var memo: Observable<String> { get }
  var diaryType: Observable<ToiletDiaryType> { get }
  var date: Observable<Date> { get }
  var errorMessage: Observable<String> { get }
  var completeSavingToiletDiary: Observable<Void> { get }
  var completeDeletingToiletDiary: Observable<Void> { get }

  func update(memo: String)
  func update(type: ToiletDiaryType)
  func update(date: Date)

  func save()
  func delete()
}

class EditToiletDiaryViewModel: BaseViewModel {

  private let parameter: EditToiletDiaryInitializeParameter
  private let dtoRelay: BehaviorRelay<EditToiletDiaryDTO>
  private let errorRelay: PublishRelay<Error> = .init()
  private let completeSavingToiletDiaryRelay: PublishRelay<Void> = .init()
  private let completeDeletingToiletDiaryRelay: PublishRelay<Void> = .init()

  private let dependency: Dependency

  init(parameter: EditToiletDiaryInitializeParameter, dependency: Dependency) {
    self.parameter = parameter
    self.dependency = dependency

    let dto = EditToiletDiaryDTO(
      memo: parameter.toiletDiary.memo,
      date: parameter.toiletDiary.date,
      type: parameter.toiletDiary.type
    )

    dtoRelay = .init(value: dto)
    super.init()
  }

}

extension EditToiletDiaryViewModel {
  struct Dependency {
    let updateUseCase: EditRecordedToiletDiaryUseCase
    let deleteUseCase: DeleteToiletDiaryUseCase
  }
}

extension EditToiletDiaryViewModel: EditToiletDiaryViewModelType {

  var memo: Observable<String> {
    dtoRelay.map({ $0.memo })
  }

  var date: Observable<Date> {
    dtoRelay.map({ $0.date })
  }

  var diaryType: Observable<ToiletDiaryType> {
    dtoRelay.map({ $0.type })
  }

  var errorMessage: Observable<String> {
    errorRelay.map({ $0.localizedDescription })
  }

  var completeSavingToiletDiary: Observable<Void> {
    completeSavingToiletDiaryRelay.asObservable()
  }

  var completeDeletingToiletDiary: Observable<Void> {
    completeDeletingToiletDiaryRelay.asObservable()
  }

  func update(date: Date) {
    var dto = dtoRelay.value
    dto.update(keyPath: \.date, valie: date)
    dtoRelay.accept(dto)
  }

  func update(memo: String) {
    var dto = dtoRelay.value
    dto.update(keyPath: \.memo, valie: memo)
    dtoRelay.accept(dto)
  }

  func update(type: ToiletDiaryType) {
    var dto = dtoRelay.value
    dto.update(keyPath: \.type, valie: type)
    dtoRelay.accept(dto)
  }

  func save() {

    let dto = dtoRelay.value
    let toiletDiary = parameter.toiletDiary

    let input = RecordUseToiletInput(
      date: dto.date,
      memo: dto.memo,
      type: dto.type,
      latitude: toiletDiary.latitude,
      longitude: toiletDiary.longitude
    )

    dependency.updateUseCase
      .execute(newInput: input, id: toiletDiary.id)
      .subscribe(
        onSuccess: {
          self.completeSavingToiletDiaryRelay.accept(())
        },
        onFailure: { error in
          self.errorRelay.accept(error)
        }
      )
      .disposed(by: disposeBag)
  }

  func delete() {
    dependency.deleteUseCase
      .execute(toiletDiary: parameter.toiletDiary)
      .subscribe(
        onSuccess: {
          self.completeDeletingToiletDiaryRelay.accept(())
        },
        onFailure: { error in
          self.errorRelay.accept(error)
        }
      )
      .disposed(by: disposeBag)
  }
}
