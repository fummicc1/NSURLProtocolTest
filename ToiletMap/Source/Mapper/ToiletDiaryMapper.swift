//
//  ToiletDiaryMapper.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/07/31.
//

import Foundation
import RxRelay
import RxSwift

class ToiletDiaryMapper {

  enum Error: Swift.Error {
    case noToiletDiaryType(text: String)
    case noToiletDiaryId
    case noMyAuthId
  }

  private let userRepository: UserRepositoryType
  private let toiletDiaryRepository: ToiletDiaryRepositoryType
  private let toiletRepository: ToiletRepositoryType
  private let mapper = Mapper.Toilet.self

  init(
    toiletDiaryRepository: ToiletDiaryRepositoryType = Repositories.toiletDiaryRepository,
    userRepository: UserRepositoryType = Repositories.userRepository,
    toiletRepository: ToiletRepositoryType = Repositories.toiletRepository
  ) {
    self.toiletDiaryRepository = toiletDiaryRepository
    self.toiletRepository = toiletRepository
    self.userRepository = userRepository
  }

  func convert(firEntity: Entity.ToiletDiary) -> Single<ToiletDiaryPresentable> {
    guard let type = ToiletDiaryType(rawValue: firEntity.toiletDiaryType) else {
      return Single.error(Error.noToiletDiaryType(text: firEntity.toiletDiaryType))
    }
    guard let id = firEntity.id else {
      return Single.error(Error.noToiletDiaryId)
    }
    let lat = firEntity.latitude
    let long = firEntity.longitude
    if let homeToilet = userRepository.user?.homeToilet, homeToilet.longitude == lat,
      long == homeToilet.longitude
    {
      return Single.just(homeToilet)
        .map({ homeToilet in
          try Mapper.HomeToilet.convert(homeToilet: homeToilet)
        })
        .map { toilet in
          let fragment = ToiletDiaryFragment(
            id: id,
            date: firEntity.date,
            memo: firEntity.memo,
            type: type,
            latitude: firEntity.latitude,
            longitude: firEntity.longitude,
            toilet: toilet
          )
          return fragment
        }
    }
    return toiletRepository.fetchToilet(
      latitude: lat,
      longitude: long,
      useCache: true
    )
    .map({ $0 as Entity.Toilet? })
    .catchAndReturn(nil)
    .map { toilet in
      return ToiletDiaryFragment(
        id: id,
        date: firEntity.date,
        memo: firEntity.memo,
        type: type,
        latitude: firEntity.latitude,
        longitude: firEntity.longitude,
        toilet: toilet == nil ? nil : self.mapper.convert(toilet: toilet!)
      )
    }
    .asSingle()
  }

  func convert(entity: LocalToiletDiary) -> Single<ToiletDiaryPresentable> {

    guard let type = ToiletDiaryType(rawValue: entity.toiletDiaryType) else {
      return Single.error(Error.noToiletDiaryType(text: entity.toiletDiaryType))
    }

    guard let toiletId = entity.toiletID else {
      let fragment = ToiletDiaryFragment(
        id: entity.id,
        date: entity.date,
        memo: entity.memo,
        type: type,
        latitude: entity.latitude,
        longitude: entity.longitude,
        toilet: nil
      )
      return .just(fragment)
    }

    let toiletAsync = toiletRepository.fetch(id: toiletId)

    return toiletAsync.map { toilet -> ToiletDiaryPresentable in

      let toiletPresentable = self.mapper.convert(toilet: toilet)

      return ToiletDiaryFragment(
        id: entity.id,
        date: entity.date,
        memo: entity.memo,
        type: type,
        latitude: entity.latitude,
        longitude: entity.longitude,
        toilet: toiletPresentable
      )
    }
  }

  func convert(fragment: ToiletDiaryPresentable, shouldCreate: Bool = false) -> Single<
    Entity.ToiletDiary
  > {
    guard let myUserId = userRepository.user?.id else {
      return .error(Error.noMyAuthId)
    }
    return toiletDiaryRepository.get(id: fragment.id).catch { error in
      if shouldCreate {
        let entity = Entity.ToiletDiary(
          ref: nil,
          createdAt: nil,
          updatedAt: nil,
          toiletDiaryType: fragment.type.rawValue,
          date: fragment.date,
          memo: fragment.memo,
          latitude: fragment.latitude,
          longitude: fragment.longitude,
          sharedUsers: [myUserId]
        )
        // 作成する
        return self.toiletDiaryRepository.create(diary: entity).flatMap({ id in
          self.toiletDiaryRepository.get(id: id)
        })
      }
      return Single<Entity.ToiletDiary>.never()
    }
  }
}
