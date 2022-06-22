//
//  UserRepository.swift
//  HOMEYO
//
//  Created by Fumiya Tanaka on 2020/12/25.
//

import Combine
import EasyFirebaseSwiftAuth
import EasyFirebaseSwiftFirestore
import FirebaseFirestore
import Foundation
import RxRelay
import RxSwift

protocol UserRepositoryType {
  var user: Entity.User? { get }
  var userObservable: Observable<Entity.User?> { get }
  var errorObservable: Observable<Error> { get }
  func create(_ homeToilet: Entity.HomeToilet, of uer: Entity.User) -> Observable<Void>
  func create(authUser: AuthUser) -> Observable<Void>
  func updateOrCreateIfNotExists(_ user: AuthUser) -> Observable<Void>
  func update(_ homeToilet: Entity.HomeToilet, of uer: Entity.User) -> Observable<Void>
  func update(_ user: Entity.User, from authUser: AuthUser) -> Observable<Void>
  func update(_ user: Entity.User) -> Observable<Void>
  func get(uid: String) -> Single<Entity.User>
  func reload()
}

enum UserRepositoryError: Error {
  case alreadyListeningUser
}

class UserRepository: UserRepositoryType {

  public init(
    firestoreClient: FirestoreClient,
    authClient: FirebaseAuthClient
  ) {
    self.firestoreClient = firestoreClient
    self.authClient = authClient

    authClient.user.compactMap({ $0?.uid })
      .removeDuplicates()
      .sink { _ in
      } receiveValue: { (uid) in
        self.startListenToUser(id: uid)
      }
      .store(in: &cancellables)
  }

  var cancellables: [AnyCancellable] = []

  private let errorRelay: PublishRelay<Error> = .init()
  private let userRelay: BehaviorRelay<Entity.User?> = .init(value: nil)

  private let authClient: FirebaseAuthClient
  private let firestoreClient: FirestoreClient

  var user: Entity.User? {
    userRelay.value
  }
  var userObservable: Observable<Entity.User?> {
    userRelay.asObservable()
  }
  var errorObservable: Observable<Error> {
    errorRelay.asObservable()
  }

  private func startListenToUser(id: String) {
    firestoreClient.listen(uid: id) { [weak self] (user: Entity.User) in
      self?.userRelay.accept(user)
    } failure: { [weak self] (error) in
      self?.errorRelay.accept(error)
    }
  }

  func get(uid: String) -> Single<Entity.User> {
    Single.create { [weak self] (singleEvent) -> Disposable in
      guard let self = self else {
        return Disposables.create()
      }
      self.firestoreClient.get(uid: uid) { (user: Entity.User) in
        singleEvent(.success(user))
      } failure: { (error) in
        singleEvent(.failure(error))
      }
      return Disposables.create()
    }
  }

  func create(_ homeToilet: Entity.HomeToilet, of uer: Entity.User) -> Observable<Void> {
    Single.create { singleEvent in
      var user = uer
      user.homeToilet = homeToilet
      self.firestoreClient.update(user) {
        singleEvent(.success(()))
      } failure: { error in
        singleEvent(.failure(error))
      }

      return Disposables.create()
    }
    .asObservable()
  }

  func create(authUser: AuthUser) -> Observable<Void> {
    let signedInAt: Timestamp? =
      authUser.signedUpAt == nil ? nil : Timestamp(date: authUser.signedUpAt!)
    let loggedInAt: Timestamp? =
      authUser.loggedInAt == nil ? nil : Timestamp(date: authUser.loggedInAt!)
    let userEntity = Entity.User(
      status: authUser.status,
      ref: nil,
      loggedInAt: loggedInAt?.dateValue(),
      signedUpAt: signedInAt?.dateValue(),
      createdAt: nil,
      updatedAt: nil
    )
    return Single.create { [weak self] singleEvent -> Disposable in
      self?.firestoreClient.create(
        userEntity,
        documentId: authUser.uid,
        success: { _ in
          singleEvent(.success(()))
        },
        failure: { error in
          singleEvent(.failure(error))
        })
      return Disposables.create()
    }.asObservable()
  }

  func updateOrCreateIfNotExists(_ user: AuthUser) -> Observable<Void> {
    Single<Entity.User>.create { singleEvent in

      let uid = user.uid

      self.firestoreClient.get(uid: uid) { (entity: Entity.User) in
        singleEvent(.success(entity))
      } failure: { error in
        singleEvent(.failure(error))
      }

      return Disposables.create()
    }.asObservable()
      .flatMap({ entity in
        self.update(entity, from: user)
      })
      .catch({ error in
        if case FirestoreClientError.failedToDecode(let data) = error, data == nil {
          return self.create(authUser: user)
        }
        return .empty()
      })
  }

  func update(_ homeToilet: Entity.HomeToilet, of uer: Entity.User) -> Observable<Void> {
    Single.create { singleEvent in
      var user = uer
      user.homeToilet = homeToilet
      self.firestoreClient.update(user) {
        singleEvent(.success(()))
      } failure: { error in
        singleEvent(.failure(error))
      }

      return Disposables.create()
    }
    .asObservable()
  }

  func update(_ user: Entity.User, from authUser: AuthUser) -> Observable<Void> {
    var user = user
    user.ref = Firestore.firestore().collection(Entity.User.collectionName).document(authUser.uid)
    user.status = authUser.status
    user.signedUpAt = authUser.signedUpAt
    user.loggedInAt = authUser.loggedInAt
    if let loggedInAt = authUser.loggedInAt {
      user.loggedInAt = loggedInAt
    }
    return update(user)
  }

  func update(_ user: Entity.User) -> Observable<Void> {
    return Single.create { [weak self] (singleEvent) -> Disposable in
      self?.firestoreClient.update(
        user,
        success: {
          singleEvent(.success(()))
        },
        failure: { (error) in
          singleEvent(.failure(error))
        })
      return Disposables.create()
    }.asObservable()
  }

  func reload() {
    userRelay.accept(userRelay.value)
  }
}
