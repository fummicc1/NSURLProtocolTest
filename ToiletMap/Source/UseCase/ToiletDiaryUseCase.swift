//
//  ToiletDiaryUseCase.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/08/02.
//

import Foundation
import RxSwift

struct ToiletDiaryUseCase {

  init(
    mapper: ToiletDiaryMapper,
    userRepository: UserRepositoryType,
    toiletRepository: ToiletRepositoryType,
    toiletDiaryRepository: ToiletDiaryRepositoryType
  ) {
    self.mapper = mapper
    self.userRepository = userRepository
    self.toiletRepository = toiletRepository
    self.toiletDiaryRepository = toiletDiaryRepository
  }

  let mapper: ToiletDiaryMapper
  let userRepository: UserRepositoryType
  let toiletRepository: ToiletRepositoryType
  let toiletDiaryRepository: ToiletDiaryRepositoryType
  private let disposeBag = DisposeBag()
}

struct RecordUseToiletInput {
  let date: Date
  let memo: String
  let type: ToiletDiaryType
  let latitude: Double
  let longitude: Double
}

protocol SyncLocalDiaryWithRemoteUseCase {
  func uploadAllLocalDiaryToFirestore() -> Single<Void>
}

protocol RecordToiletDiaryUseCase {
  func execute(input: RecordUseToiletInput) -> Observable<Void>
}

extension ToiletDiaryUseCase: RecordToiletDiaryUseCase, SyncLocalDiaryWithRemoteUseCase {

  func execute(input: RecordUseToiletInput) -> Observable<Void> {
    guard let myUid = self.userRepository.user?.id else {
      assertionFailure()
      return Observable.error(Error.noMyAuthId)
    }
    let entity = Entity.ToiletDiary(
      ref: nil,
      createdAt: nil,
      updatedAt: nil,
      toiletDiaryType: input.type.rawValue,
      date: input.date,
      memo: input.memo,
      latitude: input.latitude,
      longitude: input.longitude,
      sharedUsers: [myUid]
    )
    return
      toiletDiaryRepository
      .create(diary: entity)
      .map({ _ in () })
      .asObservable()
  }

  func uploadAllLocalDiaryToFirestore() -> Single<Void> {
    let localToilets = toiletDiaryRepository.getAllLocally()
    if localToilets.isEmpty {
      return .just(())
    }
    let entityToilet: Observable<[Entity.ToiletDiary]> = toiletDiaryRepository.listenAllLocally()
      .filter({ $0.isNotEmpty })
      .distinctUntilChanged()
      .take(1)
      .flatMap { diaries in
        Observable.from(
          diaries.map { diary in
            self.mapper.convert(entity: diary)
              .flatMap { presentable in
                self.mapper.convert(
                  fragment: presentable,
                  shouldCreate: true
                )
              }
          }
        ).merge()
          .toArray()
          .asObservable()
      }
    return entityToilet.map({ _ -> Void in
      do {
        try self.toiletDiaryRepository.getAllLocally()
          .forEach { diary in
            try diary.delete()
          }
      } catch {
        print(error)
      }
      return ()
    }).asSingle()
  }
}

protocol EditRecordedToiletDiaryUseCase {
  func execute(newInput: RecordUseToiletInput, id: String) -> Single<Void>
}

extension ToiletDiaryUseCase: EditRecordedToiletDiaryUseCase {

  enum Error: Swift.Error {
    case noMyAuthId
    case noToiletDiaryFound(id: String)
  }

  func execute(newInput: RecordUseToiletInput, id: String) -> Single<Void> {
    return toiletDiaryRepository.get(id: id)
      .flatMap { diary in
        var diary = diary
        diary.memo = newInput.memo
        diary.toiletDiaryType = newInput.type.rawValue
        diary.date = newInput.date
        return self.toiletDiaryRepository.update(diary: diary)
      }
  }

}

protocol FetchToiletDiaryUseCase {
  func execute(id: String) throws -> Single<ToiletDiaryPresentable>
}

extension ToiletDiaryUseCase: FetchToiletDiaryUseCase {
  func execute(id: String) throws -> Single<ToiletDiaryPresentable> {
    guard let diary = toiletDiaryRepository.getLocally(toiletDiaryId: id) else {
      throw Error.noToiletDiaryFound(id: id)
    }
    return mapper.convert(entity: diary)
  }
}

protocol ObserveToiletDiaryUseCase {
  func execute(id: String) throws -> Observable<ToiletDiaryPresentable>
}

extension ToiletDiaryUseCase: ObserveToiletDiaryUseCase {
  func execute(id: String) throws -> Observable<ToiletDiaryPresentable> {
    let local = toiletDiaryRepository.listenLocally(toiletDiaryId: id).flatMap { entity in
      self.mapper.convert(entity: entity)
    }
    let firestore = toiletDiaryRepository.listen(id: id).flatMap { entity in
      self.mapper.convert(firEntity: entity)
    }
    return Observable.merge(local, firestore)
  }
}

protocol ObserveAllToiletDiaryUseCase {
  func execute() -> Observable<[ToiletDiaryPresentable]>
}

extension ToiletDiaryUseCase: ObserveAllToiletDiaryUseCase {

  func execute() -> Observable<[ToiletDiaryPresentable]> {
    toiletDiaryRepository.listenAll()
      .map({ entities -> [ToiletDiaryPresentable] in
        // EntityをPresentableに変換
        entities.compactMap({ entity -> ToiletDiaryPresentable? in
          guard let id = entity.id else {
            return nil
          }
          return ToiletDiaryFragment(
            id: id,
            date: entity.date,
            memo: entity.memo,
            type: .init(rawValue: entity.toiletDiaryType) ?? .other,
            latitude: entity.latitude,
            longitude: entity.longitude,
            toilet: nil
          )
        })
      })
  }
}

protocol DeleteToiletDiaryUseCase {
  func execute(toiletDiary: ToiletDiaryPresentable) -> Single<Void>
}

extension ToiletDiaryUseCase: DeleteToiletDiaryUseCase {
  func execute(toiletDiary: ToiletDiaryPresentable) -> Single<Void> {
    let id = toiletDiary.id
    if let localToilet = toiletDiaryRepository.getLocally(toiletDiaryId: id) {
      return Single.create { singleEvent in
        do {
          try localToilet.delete()
          singleEvent(.success(()))
        } catch {
          singleEvent(.failure(error))
        }
        return Disposables.create()
      }
    } else {
      return toiletDiaryRepository.delete(firId: id)
    }
  }
}
