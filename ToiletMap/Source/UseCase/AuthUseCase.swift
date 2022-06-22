//
//  AuthUseCase.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/19.
//

import AuthenticationServices
import Foundation
import RxRelay
import RxSwift

enum AuthUseCase {}

protocol SignInAsGuestUseCaseType {
  func execute() -> Observable<Void>
}

extension AuthUseCase {

  struct SignInAsGuestUseCase: SignInAsGuestUseCaseType {

    let authRepository: AuthRepositoryType = Repositories.authRepository
    let userRepository: UserRepositoryType = Repositories.userRepository

    func execute() -> Observable<Void> {
      authRepository.signInAnonymously()
        .asObservable()
        .flatMap({ authUser in
          self.userRepository.create(authUser: authUser).asObservable()
        })
        .catch { error in
          print(error)
          return .empty()
        }
    }
  }

}

extension AuthUseCase {

  struct SigninWithAppleUseCase {

    enum Error: Swift.Error {
      case underlying(Swift.Error)
    }

    let authRepository: AuthRepositoryType = Repositories.authRepository
    let userRepository: UserRepositoryType = Repositories.userRepository
    let createMe: CreateMeUseCaseType = UserUseCase.CreateMeUseCase()
    let updateMe = UserUseCase.UpdateMeUsecase()

    func execute(onAdmitRequest: @escaping () -> Void) -> Observable<Void> {
      authRepository.signInWithApple()
        .flatMap({ credential -> Observable<AuthUser> in
          onAdmitRequest()
            credential.secret
          return self.authRepository.signIn(with: credential)
        })
        .flatMap({ authUser in
          self.userRepository.updateOrCreateIfNotExists(authUser)
            .map({ _ in authUser })
        })
        .flatMap({ authUser in
          self.userRepository.get(uid: authUser.uid)
        })
        .flatMap({ _ in
          self.updateMe.execute(keyPath: \.status, value: .signInWithApple)
        })
        .catch { error in
          #if DEVELOP
            print(error)
          #endif
          return .error(Self.Error.underlying(error))
        }
    }
  }

  struct LinkExistingUserWithNewAppleId {

    let authRepository: AuthRepositoryType = AuthRepository.shared
    let createMe: CreateMeUseCaseType = UserUseCase.CreateMeUseCase()
    let updateMe: UpdateMeUseCaseType = UserUseCase.UpdateMeUsecase()

    func execute() -> Observable<Void> {
      authRepository.signInWithApple()
        .flatMap({ credential in
          self.authRepository.link(with: credential)
        })
        .flatMap({ authUser in
          self.createMe.execute(authUser: authUser)
        })
        .flatMap({
          self.updateMe.execute(keyPath: \.status, value: .signInWithApple)
        })
    }
  }

  struct GetAuthUser {

    let authRepository: AuthRepositoryType = AuthRepository.shared

    func execute() -> Observable<AuthUser> {
      authRepository.user.compactMap({ $0 })
    }

  }

  struct DeleteCurrentUser {
    let authRepository: AuthRepositoryType = AuthRepository.shared

    func execute() -> Observable<Void> {
      authRepository.delete()
    }
  }

  struct SignOutCurrentUser {
    let authRepository: AuthRepositoryType = Repositories.authRepository
    let userRepository: UserRepositoryType = Repositories.userRepository
    let toiletRepository: ToiletRepositoryType = Repositories.toiletRepository

    func execute() -> Observable<Void> {
      authRepository.signOut()
    }
  }
}
