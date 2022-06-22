//
//  ToiletDiaryRepository.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/07/31.
//

import EasyFirebaseSwiftAuth
import EasyFirebaseSwiftFirestore
import Foundation
import RealmSwift
import RxRealm
import RxRelay
import RxSwift

protocol LocalToiletDiaryRepositoryType {

  var localToiletDiaryList: Observable<[LocalToiletDiary]> { get }

  func getLocally(toiletDiaryId id: String) -> LocalToiletDiary?
  func getAllLocally() -> [LocalToiletDiary]
  func listenLocally(toiletDiaryId id: String) -> Observable<LocalToiletDiary>
  func listenAllLocally() -> Observable<[LocalToiletDiary]>
  func deleteAllLocally() -> Observable<Void>
}

protocol FirestoreToiletDiaryRepositoryType {
  var toiletDiaryList: Observable<[Entity.ToiletDiary]> { get }

  func get(id: String) -> Single<Entity.ToiletDiary>
  func listen(id: String) -> Observable<Entity.ToiletDiary>
  func listenAll() -> Observable<[Entity.ToiletDiary]>

  func create(diary: Entity.ToiletDiary) -> Single<String>
  func update(diary: Entity.ToiletDiary) -> Single<Void>
  func delete(firId: String) -> Single<Void>
}

typealias ToiletDiaryRepositoryType = FirestoreToiletDiaryRepositoryType
  & LocalToiletDiaryRepositoryType

enum LocalToiletDiaryRepositoryError: Swift.Error {
  case noStoredLocalToiletDiary(id: String)
}

final class ToiletDiaryRepository {

  private let realm: Realm
  private let authClient: FirebaseAuthClient
  private let firestore: FirestoreClient

  private var allListeningDisposable: Disposable?

  init(
    realm: Realm = RealmInjector.shared.realm, firestore: FirestoreClient, auth: FirebaseAuthClient
  ) {
    self.realm = realm
    self.firestore = firestore
    self.authClient = auth
  }

  private let localToiletDiaryListRelay: BehaviorRelay<[LocalToiletDiary]> = BehaviorRelay(value: []
  )

  private let toiletDiaryListRelay: BehaviorRelay<[Entity.ToiletDiary]> = .init(value: [])
}

extension ToiletDiaryRepository: ToiletDiaryRepositoryType {
  var localToiletDiaryList: Observable<[LocalToiletDiary]> {
    localToiletDiaryListRelay.asObservable()
  }

  var toiletDiaryList: Observable<[Entity.ToiletDiary]> {
    toiletDiaryListRelay.asObservable()
  }

  func getAllLocally() -> [LocalToiletDiary] {
    realm.objects(LocalToiletDiary.self).map({ $0 })
  }

  func getLocally(toiletDiaryId id: String) -> LocalToiletDiary? {
    guard let ret = realm.objects(LocalToiletDiary.self).filter("id = %@", id).first else {
      return nil
    }
    return ret
  }

  func listenLocally(toiletDiaryId id: String) -> Observable<LocalToiletDiary> {
    guard let object = realm.objects(LocalToiletDiary.self).filter({ $0.id == id }).first else {
      return Observable.error(LocalToiletDiaryRepositoryError.noStoredLocalToiletDiary(id: id))
    }
    return Observable.from(object: object)
  }

  func listenAllLocally() -> Observable<[LocalToiletDiary]> {
    let objects = realm.objects(LocalToiletDiary.self)
    let ret = Observable.array(from: objects)
    allListeningDisposable?.dispose()
    allListeningDisposable = ret.bind(to: localToiletDiaryListRelay)
    return ret
  }

  func deleteAllLocally() -> Observable<Void> {
    let diaries = localToiletDiaryListRelay.value
    return Observable.create { observer in
      do {
        try diaries.forEach { diary in
          try diary.delete()
        }
        observer.onNext(())
      } catch {
        observer.onError(error)
      }
      return Disposables.create()
    }
  }

  func get(id: String) -> Single<Entity.ToiletDiary> {
    Single.create { [weak self] singleEvent in
      self?.firestore.get(uid: id) { (diary: Entity.ToiletDiary) in
        singleEvent(.success(diary))
      } failure: { error in
        singleEvent(.failure(error))
      }
      return Disposables.create()
    }
  }

  func listenAll() -> Observable<[Entity.ToiletDiary]> {
    Observable.create { [weak self] observer in
      let arrayFilter = FirestoreContainFilter(
        fieldPath: "shared_users",
        value: self?.authClient.uid
      )
      self?.firestore.listen(
        filter: [arrayFilter],
        order: [],
        limit: nil
      ) { (diaries: [Entity.ToiletDiary]) in
        observer.onNext(diaries)
      } failure: { error in
        observer.onError(error)
      }
      return Disposables.create()
    }
  }

  func listen(id: String) -> Observable<Entity.ToiletDiary> {
    Observable.create { [weak self] observer in
      self?.firestore.listen(uid: id) { (diary: Entity.ToiletDiary) in
        observer.onNext(diary)
      } failure: { error in
        observer.onError(error)
      }
      return Disposables.create()
    }
  }

  func create(diary: Entity.ToiletDiary) -> Single<String> {
    Single.create { singleEvent in
      self.firestore.create(diary) { ref in
        singleEvent(.success(ref.documentID))
      } failure: { error in
        singleEvent(.failure(error))
      }
      return Disposables.create()
    }
  }

  func update(diary: Entity.ToiletDiary) -> Single<Void> {
    Single.create { singleEvent in
      self.firestore.update(diary) {
        singleEvent(.success(()))
      } failure: { error in
        singleEvent(.failure(error))
      }

      return Disposables.create()
    }
  }

  func delete(firId: String) -> Single<Void> {
    Single.create { singleEvent in
      self.firestore.delete(id: firId, type: Entity.ToiletDiary.self) { error in
        if let error = error {
          singleEvent(.failure(error))
        } else {
          singleEvent(.success(()))
        }
      }
      return Disposables.create()
    }
  }
}
