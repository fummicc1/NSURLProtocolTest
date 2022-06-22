//
//  UserUseCase.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/20.
//

import Foundation
import RxRelay
import RxSwift

enum UserUseCase {

}

protocol GetUserUseCaseType {
  func execute(id: String) -> Single<UserPresentable>
}

extension UserUseCase {
  struct GetUserUseCase: GetUserUseCaseType {
    let userRepository: UserRepositoryType = Repositories.userRepository
    let mapper = Mapper.self

    func execute(id: String) -> Single<UserPresentable> {
      userRepository.get(uid: id)
        .map({ entity in
          try self.mapper.User.convert(user: entity)
        })
    }
  }
}

protocol GetMeUseCaseType {
  func execute() -> Single<MePresentable>
}

extension UserUseCase {
  struct GetMeUseCase: GetMeUseCaseType {

    enum Error: Swift.Error {
      case noMe
    }

    let userRepository: UserRepositoryType = Repositories.userRepository
    let mapper = Mapper.self

    func execute() -> Single<MePresentable> {
      guard let meUid = userRepository.user?.uid else {
        return .error(Error.noMe)
      }
      return userRepository.get(uid: meUid).map({ entity in
        try self.mapper.Me.convert(user: entity)
      })
    }
  }
}

protocol ObserveMeUseCaseType {
  func execute() -> Observable<MePresentable>
}

extension UserUseCase {
  struct ObserveMeUsecase: ObserveMeUseCaseType {

    enum Error: Swift.Error {
      case noMe
    }

    let userRepository: UserRepositoryType = Repositories.userRepository
    let mapper = Mapper.self

    func execute() -> Observable<MePresentable> {
      return userRepository.userObservable
        .compactMap({ $0 })
        .map({ (entity: Entity.User) -> MePresentable in
          return try self.mapper.Me.convert(user: entity)
        })
    }
  }
}

protocol CreateMeUseCaseType {
  func execute(authUser: AuthUser) -> Single<Void>
}

extension UserUseCase {
  struct CreateMeUseCase: CreateMeUseCaseType {

    init(
      userRepository: UserRepositoryType = Repositories.userRepository
    ) {
      self.userRepository = userRepository
    }

    let userRepository: UserRepositoryType

    func execute(authUser: AuthUser) -> Single<Void> {
      userRepository.create(authUser: authUser).asSingle()
    }
  }
}

protocol UpdateMeUseCaseType {
  func execute(me: MePresentable) -> Single<Void>
  func execute<V>(keyPath: WritableKeyPath<MeFragment, V>, value: V) -> Observable<Void>
}

extension UserUseCase {

  struct UpdateMeUsecase: UpdateMeUseCaseType {
    enum Error: Swift.Error {
      case noMe
    }

    let userRepository: UserRepositoryType = Repositories.userRepository
    let getMe: GetMeUseCase = GetMeUseCase()
    let mapper = Mapper.self

    func execute(me: MePresentable) -> Single<Void> {
      do {
        return try mapper.Me.convert(me: me)
          .flatMap({ user in
            self.userRepository
              .update(user)
              .asSingle()
          })
      } catch {
        return Single.error(error)
      }
    }

    func execute<V>(keyPath: WritableKeyPath<MeFragment, V>, value: V) -> Observable<Void> {
      getMe.execute()
        .compactMap({ me in
          guard var me = me as? MeFragment else {
            return nil
          }
          me[keyPath: keyPath] = value
          return me
        })
        .asObservable()
        .flatMap({ (me: MeFragment) in
          execute(me: me)
        })
    }
  }
}
