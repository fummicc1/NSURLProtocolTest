//
//  AuthRepository.swift
//  BuSuc
//
//  Created by Fumiya Tanaka on 2020/12/31.
//

import AuthenticationServices
import Combine
import EasyFirebaseSwiftAuth
import FirebaseAuth
import Foundation
import RxCombine
import RxRelay
import RxSwift

struct AuthUser {
  let uid: String
  let email: String?
  let displayName: String?
  let signedUpAt: Date?
  let loggedInAt: Date?
  let status: Entity.User.Status
}

protocol AuthRepositoryType {
  var user: Observable<AuthUser?> { get }
  var isLoggedIn: Bool { get }
  var userValue: AuthUser? { get }
  func signInAnonymously() -> Single<AuthUser>
  func signInWithApple() -> Observable<OAuthCredential>
  func signIn(with credential: OAuthCredential) -> Observable<AuthUser>
  func link(with credential: OAuthCredential) -> Observable<AuthUser>
  func delete() -> Observable<Void>
  func signOut() -> Observable<Void>
  func reload()
}

class AuthRepository: NSObject {

  static let shared: AuthRepositoryType = Repositories.authRepository
  var cancellables: Set<AnyCancellable> = []

  public init(
    toiletRepository: ToiletRepositoryType,
    dependency: Dependency
  ) {

    self.toiletRepository = toiletRepository
    self.dependency = dependency

    super.init()

    dependency.firAuth.user.sink { _ in
    } receiveValue: { [weak self] (user) in
      guard let user = user else {
        self?.userRelay.accept(nil)
        return
      }
      let email: String?
      let status: Entity.User.Status
      if let userInfo = user.providerData.first(where: { $0.providerID == "apple.com" }) {
        email = userInfo.email
        assert(userInfo.email?.isNotEmpty ?? false)
        status = .signInWithApple
      } else {
        email = nil
        status = .signInAnonymously
      }
      let authUser = AuthUser(
        uid: user.uid,
        email: email,
        displayName: user.displayName,
        signedUpAt: user.metadata.creationDate,
        loggedInAt: user.metadata.lastSignInDate,
        status: status
      )
      self?.userRelay.accept(authUser)
    }.store(in: &cancellables)
  }

  private var toiletRepository: ToiletRepositoryType
  private let userRelay: BehaviorRelay<AuthUser?> = .init(value: nil)
  private let authorizationFlowSubject: PublishRelay<(token: String?, nonce: String?)> = .init()

  var dependency: Dependency

  struct Dependency {
    let auth: AppleAuthClient
    let firAuth: FirebaseAuthClient

    init(
      auth: AppleAuthClient,
      firAuth: FirebaseAuthClient
    ) {
      self.auth = auth
      self.firAuth = firAuth
    }
  }
}

enum AuthRepositoryError: Swift.Error {
  case appleIdHasAlreadyLinkedWithOtherAccount
}

extension AuthRepository: AuthRepositoryType {

  var isLoggedIn: Bool {
    dependency.firAuth.uid != nil
  }

  var user: Observable<AuthUser?> {
    userRelay.asObservable()
  }

  var userValue: AuthUser? {
    userRelay.value
  }

  func signInWithApple() -> Observable<OAuthCredential> {
    dependency.auth.startSignInWithAppleFlow()
    return Observable.combineLatest(
      dependency.auth.error.asObservable(),
      dependency.auth.credential.asObservable()
    )
    // 最初の状態（errorもcredentialもnil）を避ける
    .filter({ $0 != nil || $1 != nil })
    .flatMap { (error, credential) -> Observable<OAuthCredential> in
      if let credential = credential {
        return Observable.just(credential)
      }
      if let error = error {
        return Observable.error(error)
      }
      assertionFailure("Unexpected condition")
      return .never()
    }
  }

  func link(with credential: OAuthCredential) -> Observable<AuthUser> {
    Single.create { [weak self] (singleEvent) -> Disposable in
      guard let self = self else {
        return Disposables.create()
      }
      self.dependency.firAuth
        .link(with: credential)
        .sink(
          receiveCompletion: { result in
            switch result {
            case .finished:
              break
            case .failure(let error):
              let error = error as NSError
              if error.code == 17025 {
                singleEvent(.failure(AuthRepositoryError.appleIdHasAlreadyLinkedWithOtherAccount))
                return
              }
              singleEvent(.failure(error))
            }
          },
          receiveValue: { user in
            let status: Entity.User.Status
            let email: String?
            if let info = user.providerData.first(where: { $0.providerID == "apple.com" }) {
              status = .signInWithApple
              email = info.email
            } else if user.isAnonymous {
              status = .signInAnonymously
              email = nil
            } else {
              status = .other
              email = nil
            }
            let authuser = AuthUser(
              uid: user.uid,
              email: email,
              displayName: user.displayName,
              signedUpAt: user.metadata.creationDate,
              loggedInAt: user.metadata.lastSignInDate,
              status: status
            )
            self.userRelay.accept(authuser)
            singleEvent(.success(authuser))
          }
        )
        .store(in: &self.cancellables)
      return Disposables.create()
    }.asObservable()
  }

  func signIn(with credential: OAuthCredential) -> Observable<AuthUser> {
    Single.create { [weak self] singleEvent -> Disposable in
      guard let self = self else {
        return Disposables.create()
      }
      self.dependency.firAuth.signIn(with: credential).sink(
        receiveCompletion: { result in
          switch result {
          case .finished:
            break
          case .failure(let error):
            singleEvent(.failure(error))
          }
        },
        receiveValue: { user in
          let status: Entity.User.Status
          let email: String?
          if let info = user.providerData.first(where: { $0.providerID == "apple.com" }) {
            status = .signInWithApple
            email = info.email
          } else if user.isAnonymous {
            status = .signInAnonymously
            email = nil
          } else {
            status = .other
            email = nil
          }
          let authuser = AuthUser(
            uid: user.uid,
            email: email,
            displayName: user.displayName,
            signedUpAt: user.metadata.creationDate,
            loggedInAt: user.metadata.lastSignInDate,
            status: status
          )
          self.userRelay.accept(authuser)
          singleEvent(.success(authuser))
        }
      ).store(in: &self.cancellables)
      return Disposables.create()
    }.asObservable()
  }

  func signInAnonymously() -> Single<AuthUser> {
    Single.create { [weak self] (singleEvent) -> Disposable in
      guard let self = self else {
        return Disposables.create()
      }
      self.dependency.firAuth.signInAnonymously().sink {
        (completion: Subscribers.Completion<Error>) in
        switch completion {
        case .finished:
          break
        case .failure(let error):
          singleEvent(.failure(error))
        }
      } receiveValue: { user in
        let authUser = AuthUser(
          uid: user.uid,
          email: nil,
          displayName: user.displayName,
          signedUpAt: user.metadata.creationDate,
          loggedInAt: user.metadata.lastSignInDate,
          status: .signInAnonymously
        )
        singleEvent(.success(authUser))
      }.store(in: &self.cancellables)

      return Disposables.create()
    }
  }

  func delete() -> Observable<Void> {
    Single.create { singleEvent -> Disposable in
      self.dependency.firAuth.delete().sink(receiveCompletion: { completion in
        switch completion {
        case .failure(let error):
          singleEvent(.failure(error))
        default:
          break
        }
      }) {
        singleEvent(.success(()))
      }
      .store(in: &self.cancellables)
      return Disposables.create()
    }
    .asObservable()
  }

  func signOut() -> Observable<Void> {
    Single.create { singleEvent in
      self.dependency.firAuth.signOut().sink(receiveCompletion: { completion in
        switch completion {
        case .failure(let error):
          singleEvent(.failure(error))
        default:
          break
        }
      }) {
        singleEvent(.success(()))
      }
      .store(in: &self.cancellables)
      return Disposables.create()
    }.asObservable()
  }

  func reload() {
    userRelay.accept(userRelay.value)
  }
}
