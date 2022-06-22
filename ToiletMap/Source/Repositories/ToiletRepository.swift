//
//  ToiletRepository.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/01/08.
//

import Combine
import EasyFirebaseSwiftAuth
import EasyFirebaseSwiftFirestore
import FirebaseFirestore
import Foundation
import RxRelay
import RxSwift

protocol ToiletRepositoryType {
  var toiles: [Entity.Toilet] { get }
  var archivedToilets: [Entity.ArchivedToilet] { get }
  var createdToilets: [Entity.Toilet] { get }
  var toiletsObservable: Observable<[Entity.Toilet]> { get }
  var archivedToiletsObservable: Observable<[Entity.ArchivedToilet]> { get }
  var createdToiletsObservable: Observable<[Entity.Toilet]> { get }

  // MARK: Get
  func listen(id: String) -> Observable<Entity.Toilet>
  func fetchToilet(latitude: Double, longitude: Double, useCache: Bool) -> Observable<
    Entity.Toilet?
  >
  func fetchArchivedToilet(of uid: String, latitude: Double, longitude: Double, useCache: Bool)
    -> Single<Entity.ArchivedToilet>
  func fetch(id: String, of uid: String) -> Single<Entity.ArchivedToilet>
  func fetch(id: String) -> Single<Entity.Toilet>
  func fetch(latRange: Range<Double>, longRange: Range<Double>) -> Observable<[Entity.Toilet]>

  // MARK: Write
  func create(toilet: Entity.Toilet, id: String?) -> Single<DocumentReference>
  func delete(toilet: Entity.Toilet) -> Single<Void>
  func create(archivedToilet: Entity.ArchivedToilet, id: String?) -> Single<DocumentReference>
  func delete(archivedToilet: Entity.ArchivedToilet) -> Single<Void>
  func reload()
  func clearAllToilets()
}

class ToiletRepository: ToiletRepositoryType {

  enum Error: Swift.Error {
    case notFound
  }

  static let shared = Repositories.toiletRepository

  private let disposeBag: DisposeBag = .init()

  init(
    userRepository: UserRepositoryType,
    firestore: FirestoreClient,
    auth: FirebaseAuthClient
  ) {
    self.userRepository = userRepository
    self.firestore = firestore
    self.auth = auth

    userRepository.userObservable
      .share()
      .subscribe(onNext: { [weak self] user in
        if let user = user, let uid = user.uid {

          self?.listenArchivedToilets(of: uid)

          self?.firestore.listen(
            filter: [FirestoreEqualFilter(fieldPath: "sender", value: uid)],
            order: [],
            limit: nil
          ) { (myCreatingToilets: [Entity.CreatedToilet]) in
            self?.createdToiletsRelay.accept(
              myCreatingToilets.compactMap({ $0.convertToToilet() })
            )
          } failure: { (error) in
            #if DEBUG
              print(error)
            #endif
          }

          self?.firestore.listen(
            filter: [],
            order: [],
            limit: 1000
          ) { (toilets: [Entity.Toilet]) in
            self?.toiletsRelay.accept(toilets)
          } failure: { (error) in
            #if DEBUG
              print(error)
            #endif
          }
        }
      })
      .disposed(by: disposeBag)
  }

  private let userRepository: UserRepositoryType
  private let firestore: FirestoreClient
  private let auth: FirebaseAuthClient

  private let toiletsRelay: BehaviorRelay<[Entity.Toilet]> = .init(value: [])
  private let archivedToiletsRelay: BehaviorRelay<[Entity.ArchivedToilet]> = .init(value: [])
  private let createdToiletsRelay: BehaviorRelay<[Entity.Toilet]> = .init(value: [])

  var toiles: [Entity.Toilet] {
    toiletsRelay.value
  }

  var createdToilets: [Entity.Toilet] {
    createdToiletsRelay.value
  }

  var archivedToilets: [Entity.ArchivedToilet] {
    archivedToiletsRelay.value
  }

  var toiletsObservable: Observable<[Entity.Toilet]> {
    toiletsRelay.asObservable().catchAndReturn([])
  }

  var archivedToiletsObservable: Observable<[Entity.ArchivedToilet]> {
    archivedToiletsRelay.asObservable().catchAndReturn([])
  }

  var createdToiletsObservable: Observable<[Entity.Toilet]> {
    createdToiletsRelay.asObservable().catchAndReturn([])
  }

  func listenArchivedToilets(of myUid: String) {
    firestore.listen(
      parent: myUid,
      superParent: nil,
      filter: [],
      order: [
        DefaultFirestoreQueryOrder(
          fieldPath: "updated_at",
          isAscending: false
        )
      ],
      limit: 50
    ) { (archivedToilets: [Entity.ArchivedToilet]) in
      self.archivedToiletsRelay.accept(archivedToilets)
    } failure: { (error) in
      #if DEBUG
        print(error)
      #endif
    }
  }

  func create(toilet: Entity.Toilet, id: String?) -> Single<DocumentReference> {
    return Single.create { [weak self] (singleEvent) -> Disposable in
      guard let self = self else {
        return Disposables.create()
      }

      self.firestore.create(
        toilet,
        documentId: id
      ) { ref in
        singleEvent(.success(ref))
      } failure: { error in
        singleEvent(.failure(error))
      }
      return Disposables.create()
    }
  }

  func delete(toilet: Entity.Toilet) -> Single<Void> {
    return Single.create { [weak self] (singleEvent) -> Disposable in
      guard let self = self else {
        return Disposables.create()
      }
      self.firestore.delete(toilet) {
        singleEvent(.success(()))
      } failure: { (error) in
        singleEvent(.failure(error))
      }

      return Disposables.create()
    }
  }

  func create(archivedToilet: Entity.ArchivedToilet, id: String?) -> Single<DocumentReference> {
    guard let uid = auth.uid else {
      return .error(FirebaseAuthClientError.noAuthData)
    }
    return Single.create { [weak self] (singleEvent) -> Disposable in
      guard let self = self else {
        return Disposables.create()
      }

      self.firestore.create(
        archivedToilet,
        documentId: id,
        parent: uid,
        superParent: nil,
        success: { ref in
          singleEvent(.success(ref))
        },
        failure: { error in
          singleEvent(.failure(error))
        })
      return Disposables.create()
    }
  }

  func listen(id: String) -> Observable<Entity.Toilet> {
    .create { (observer) -> Disposable in
      self.firestore.listen(uid: id) { (toilet: Entity.Toilet) in
        observer.onNext(toilet)
      } failure: { (error) in
        observer.onError(error)
      }
      return Disposables.create()
    }.share()
  }

  func fetchToilet(latitude: Double, longitude: Double, useCache: Bool) -> Observable<
    Entity.Toilet?
  > {
    return Observable.create { (observer) -> Disposable in
      self.firestore.get(
        filter: [
          FirestoreEqualFilter(
            fieldPath: "latitude",
            value: Double(round(latitude * pow(10, 8)) / pow(10, 8))
          ),
          FirestoreEqualFilter(
            fieldPath: "longitude",
            value: Double(round(longitude * pow(10, 8)) / pow(10, 8))
          ),
        ],
        includeCache: useCache,
        order: [],
        limit: nil
      ) { (toilets: [Entity.Toilet]) in
        guard let toilet = toilets.first else {
          observer.onNext(nil)
          return
        }
        observer.onNext(toilet)
      } failure: { (error) in
        observer.onError(error)
      }
      return Disposables.create()
    }
  }

  func fetchArchivedToilet(of uid: String, latitude: Double, longitude: Double, useCache: Bool)
    -> Single<Entity.ArchivedToilet>
  {
    return Single.create { (singleEvent) -> Disposable in
      self.firestore.get(
        parent: uid,
        superParent: nil,
        filter: [
          FirestoreEqualFilter(fieldPath: "latitude", value: latitude),
          FirestoreEqualFilter(fieldPath: "longitude", value: longitude),
        ],
        includeCache: useCache,
        order: [],
        limit: nil
      ) { (toilets: [Entity.ArchivedToilet]) in
        guard let toilet = toilets.first else {
          return
        }
        singleEvent(.success(toilet))
      } failure: { (error) in
        singleEvent(.failure(error))
      }
      return Disposables.create()
    }
  }

  func fetch(id: String) -> Single<Entity.Toilet> {
    Single.create { [weak self] (singleEvent) -> Disposable in
      guard let self = self else {
        return Disposables.create()
      }
      self.firestore.get(uid: id) { (toilet: Entity.Toilet) in
        singleEvent(.success(toilet))
      } failure: { (error) in
        singleEvent(.failure(error))
      }

      return Disposables.create()
    }
  }

  func fetch(id: String, of uid: String) -> Single<Entity.ArchivedToilet> {
    Single.create { (singleEvent) -> Disposable in
      self.firestore.get(parent: uid, superParent: nil, docId: id) {
        (toilet: Entity.ArchivedToilet) in
        singleEvent(.success(toilet))
      } failure: { (error) in
        singleEvent(.failure(error))
      }
      return Disposables.create()
    }
  }

  func fetch(latRange: Range<Double>, longRange: Range<Double>) -> Observable<[Entity.Toilet]> {
    .create { (observer) -> Disposable in

      self.firestore.get(
        filter: [
          FirestoreRangeFilter(
            fieldPath: "latitude",
            value: latRange
          ),
          FirestoreRangeFilter(
            fieldPath: "longitude",
            value: longRange
          ),
        ],
        order: [],
        limit: 50
      ) { (toilets: [Entity.Toilet]) in
        observer.onNext(toilets)
      } failure: { (error) in
        observer.onError(error)
      }
      return Disposables.create()
    }
  }

  func delete(archivedToilet: Entity.ArchivedToilet) -> Single<Void> {
    Single.create { [weak self] (singleEvent) -> Disposable in
      self?.firestore.delete(archivedToilet) {
        singleEvent(.success(()))
      } failure: { (error) in
        singleEvent(.failure(error))
      }
      return Disposables.create()
    }
  }

  func reload() {
    toiletsRelay.accept(toiletsRelay.value)
  }

  func clearAllToilets() {
    toiletsRelay.accept([])
    createdToiletsRelay.accept([])
    archivedToiletsRelay.accept([])
  }
}
