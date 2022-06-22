//
//  ArchivedToiletUseCase.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/19.
//

import CoreLocation
import FirebaseFirestore
import Foundation
import RxSwift

enum ArchivedToiletUseCase {}

protocol CreateArchivedToiletUseCaseType {
  func execute(from toilet: ToiletPresentable) -> Single<ArchivedToiletPresentable>
}

extension ArchivedToiletUseCase {
  struct CreateArchivedToiletUseCase: CreateArchivedToiletUseCaseType {

    enum Error: Swift.Error {
      case noMe
    }

    let toiletRepository: ToiletRepositoryType = Repositories.toiletRepository
    let userRepository: UserRepositoryType = Repositories.userRepository
    let toiletRefGenerator = ToiletRefGenerator()
    let mapper = Mapper.self

    func execute(from toilet: ToiletPresentable) -> Single<ArchivedToiletPresentable> {

      guard let senderUid = userRepository.user?.uid else {
        return .error(Error.noMe)
      }

      let senderFragment = UserFragment(uid: senderUid)

      return toiletRefGenerator.generate(
        at: CLLocationCoordinate2D(
          latitude: toilet.latitude,
          longitude: toilet.longitude
        )
      ).flatMap({ (toiletRef, isNew) -> Single<ArchivedToiletPresentable> in

        let archivedToilet = ArchivedToiletFragment(
          toiletRef: toiletRef,
          sender: senderFragment,
          name: toilet.name,
          detail: toilet.detail,
          latitude: toilet.latitude,
          longitude: toilet.longitude,
          ref: nil,
          createdAt: nil,
          updatedAt: nil,
          isArchived: true
        )

        if !isNew {
          return .just(archivedToilet)
        }

        let toiletEntity = Entity.Toilet(
          sender: nil,
          name: toilet.name,
          detail: toilet.detail,
          latitude: toilet.latitude,
          longitude: toilet.longitude,
          ref: nil,
          createdAt: nil,
          updatedAt: nil
        )

        return self.toiletRepository.create(
          toilet: toiletEntity,
          id: toiletRef.documentID
        ).map({ _ in
          archivedToilet
        })
      })
      .map({ presentable in
        self.mapper.ArchivedToilet.convert(toilet: presentable)
      })
      .flatMap({ entity -> Single<DocumentReference> in
        var entity = entity
        let id = entity.ref?.documentID
        entity.ref = nil
        return self.toiletRepository.create(archivedToilet: entity, id: id)
      })
      .flatMap({ ref in
        self.toiletRepository.fetch(id: ref.documentID, of: senderUid)
      })
      .map({ entity in
        try self.mapper.ArchivedToilet.convert(toilet: entity)
      })
    }
  }
}

protocol ObserveArchivedToiletsUseCaseType {
  func execute() -> Observable<[ArchivedToiletPresentable]>
}

protocol GetArchivedToiletUseCaseType {
  func execute(id: String) -> Single<ArchivedToiletPresentable>
}

extension ArchivedToiletUseCase {

  struct ObserveArchivedToiletsUseCase: ObserveArchivedToiletsUseCaseType {

    let toiletRepository: ToiletRepositoryType = Repositories.toiletRepository
    let mapper = Mapper.self

    func execute() -> Observable<[ArchivedToiletPresentable]> {
      toiletRepository.archivedToiletsObservable.map({ (toilets: [Entity.ArchivedToilet]) in
        try toilets.map({ archive in
          try self.mapper.ArchivedToilet.convert(toilet: archive)
        })
      })
    }
  }

  struct GetArchivedToiletUseCase: GetArchivedToiletUseCaseType {

    enum Error: Swift.Error {
      case noMe
    }

    let toiletRepository: ToiletRepositoryType = Repositories.toiletRepository
    let userRepository: UserRepositoryType = Repositories.userRepository
    let mapper = Mapper.self

    func execute(id: String) -> Single<ArchivedToiletPresentable> {
      guard let meUid = userRepository.user?.uid else {
        return .error(Error.noMe)
      }
      return toiletRepository.fetch(id: id, of: meUid).map({ archived in
        try self.mapper.ArchivedToilet.convert(toilet: archived)
      })
    }
  }

  struct DeleteArchivedToiletUseCase {

    enum Error: Swift.Error {
      case noMe
    }

    let toiletRepository: ToiletRepositoryType = Repositories.toiletRepository
    let userRepository: UserRepositoryType = Repositories.userRepository
    let mapper = Mapper.self

    func execute(archivedId: String) -> Single<Void> {
      guard let meUid = userRepository.user?.uid else {
        return .error(Error.noMe)
      }

      return toiletRepository.fetch(
        id: archivedId,
        of: meUid
      ).flatMap({ archived in
        self.toiletRepository.delete(archivedToilet: archived)
      })
    }

  }
}
