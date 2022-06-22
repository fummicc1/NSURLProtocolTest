//
//  HomeToiletUsecase.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/05/24.
//

import Foundation
import RxCocoa
import RxSwift

enum HomeToiletUsecase {

  enum Error: Swift.Error {
    case noMeFound
  }

  struct CreateHomeToilet {
    let userRepository: UserRepositoryType = Repositories.userRepository
    let mapper = Mapper.self

    func execute(homeToilet: HomeToiletPresentable) -> Single<Void> {
      guard let me = userRepository.user else {
        return .never()
      }
      do {
        let homeToiletEntity = try mapper.HomeToilet.convert(presentable: homeToilet)
        return homeToiletEntity.flatMap({ entity in
          self.userRepository.create(entity, of: me).asSingle()
        })
      } catch {
        return .error(error)
      }
    }
  }

  struct UpdateHomeToilet {
    let userRepository: UserRepositoryType = Repositories.userRepository
    let mapper = Mapper.self

    func execute(homeToilet: HomeToiletPresentable) -> Single<Void> {
      guard let me = userRepository.user else {
        return .never()
      }
      do {
        let homeToiletEntity = try mapper.HomeToilet.convert(presentable: homeToilet)
        return homeToiletEntity.flatMap({ entity in
          self.userRepository.update(entity, of: me).asSingle()
        })
      } catch {
        return .error(error)
      }
    }
  }

  struct ObserveHomeToilet {
    let userRepository: UserRepositoryType = Repositories.userRepository
    let mapper = Mapper.self

    func execute() -> Observable<HomeToiletPresentable> {
      let meObservable = userRepository.userObservable
      return
        meObservable
        .compactMap({ $0 })
        .compactMap({ (me: Entity.User) -> Entity.HomeToilet? in
          me.homeToilet
        })
        .map({ entity in
          try self.mapper.HomeToilet.convert(homeToilet: entity)
        })
    }
  }

  struct GetHomeToilet {
    let userRepository: UserRepositoryType = Repositories.userRepository
    let mapper = Mapper.self

    func execute() -> Single<HomeToiletPresentable> {
      let meObservable = userRepository.userObservable
      return
        meObservable
        .compactMap({ $0 })
        .compactMap({ (me: Entity.User) -> Entity.HomeToilet? in
          me.homeToilet
        })
        .map({ entity in
          try self.mapper.HomeToilet.convert(homeToilet: entity)
        })
        .asSingle()
    }
  }
}
