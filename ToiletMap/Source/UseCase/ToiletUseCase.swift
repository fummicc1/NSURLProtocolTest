//
//  ToiletUseCase.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/18.
//

import CoreLocation
import FirebaseFirestore
import Foundation
import MapKit
import RxRelay
import RxSwift

enum ToiletUseCase {}

protocol CreateToiletUseCaseType {
  func execute(
    name: String,
    detail: String?,
    location: CLLocationCoordinate2D
  ) -> Single<Void>

  func execute(presentable: ToiletPresentable) -> Single<Void>
}

extension ToiletUseCase {
  struct CreateToiletUseCase: CreateToiletUseCaseType {
    init(
      toiletRepository: ToiletRepositoryType = Repositories.toiletRepository,
      refGenerator: ToiletRefGeneratorType = ToiletRefGenerator(),
      userRepository: UserRepositoryType = Repositories.userRepository,
      getToiletUseCase: ToiletUseCase.GetToiletUseCase = ToiletUseCase.GetToiletUseCase(),
      mapper: Mapper.Type = Mapper.self
    ) {
      self.toiletRepository = toiletRepository
      self.refGenerator = refGenerator
      self.userRepository = userRepository
      self.getToiletUseCase = getToiletUseCase
      self.mapper = mapper
    }

    enum Error: Swift.Error {
      case noMe
    }

    let toiletRepository: ToiletRepositoryType
    let refGenerator: ToiletRefGeneratorType
    let userRepository: UserRepositoryType
    let getToiletUseCase: GetToiletUseCase

    let mapper: Mapper.Type

    func execute(
      name: String,
      detail: String?,
      location: CLLocationCoordinate2D
    ) -> Single<Void> {
      guard let senderUid = userRepository.user?.uid else {
        return .error(Error.noMe)
      }

      let sender = UserFragment(uid: senderUid)
      let ref = refGenerator.generate(at: location)

      return
        ref
        .map({ (ref, _) -> ToiletPresentable in
          let fragment = ToiletFragment(
            sender: sender,
            name: name,
            detail: detail,
            latitude: location.latitude,
            longitude: location.longitude,
            ref: ref,
            createdAt: nil,
            updatedAt: nil,
            isArchived: false
          )
          return fragment
        })
        .flatMap({ fragment in
          var toilet = mapper.Toilet.convert(toilet: fragment)
          toilet.ref = nil
          return self.toiletRepository.create(
            toilet: toilet,
            id: fragment.ref?.documentID
          ).map({ _ in () })
        })
    }

    func execute(
      presentable: ToiletPresentable
    ) -> Single<Void> {
      var presentable = presentable
      let coordinate = CLLocationCoordinate2D(
        latitude: presentable.latitude,
        longitude: presentable.longitude
      )
      let ref = refGenerator.generate(at: coordinate)

      return
        ref
        .map({ (ref, _) -> Entity.Toilet in
          presentable.ref = ref
          return self.mapper.Toilet
            .convert(toilet: presentable)
        })
        .flatMap({ toilet in
          var toilet = toilet
          let id = toilet.ref?.documentID
          toilet.ref = nil
          return self.toiletRepository.create(toilet: toilet, id: id)
            .map({ _ in () })
        })
    }
  }
}

protocol UpdateToiletUseCaseType {
  func execute(toilet: ToiletPresentable) -> Single<Void>
}

extension ToiletUseCase {
  struct UpdateToiletUseCase: UpdateToiletUseCaseType {

    init(
      toiletRepository: ToiletRepositoryType = Repositories.toiletRepository,
      mapper: Mapper.Type = Mapper.self
    ) {
      self.toiletRepository = toiletRepository
      self.mapper = mapper
    }

    let toiletRepository: ToiletRepositoryType
    let mapper: Mapper.Type

    func execute(toilet: ToiletPresentable) -> Single<Void> {
      do {
        let entity = mapper.Toilet.convert(toilet: toilet)
        fatalError()
      } catch {
        return .error(error)
      }
    }
  }
}

protocol DeleteToiletUseCaseType {
  func execute(toilet: ToiletPresentable) -> Single<Void>
}

extension ToiletUseCase {
  struct DeleteToiletUseCase: DeleteToiletUseCaseType {

    init(
      toiletRepository: ToiletRepositoryType = Repositories.toiletRepository,
      mapper: Mapper.Type = Mapper.self
    ) {
      self.toiletRepository = toiletRepository
      self.mapper = mapper
    }

    let toiletRepository: ToiletRepositoryType
    let mapper: Mapper.Type

    func execute(toilet: ToiletPresentable) -> Single<Void> {
      let entity = mapper.Toilet.convert(toilet: toilet)
      return self.toiletRepository.delete(toilet: entity)
    }
  }
}

protocol ObserveToiletUseCaseType {
  func execute(id: String) -> Observable<ToiletPresentable>
}

extension ToiletUseCase {
  struct ObserveToiletUseCase: ObserveToiletUseCaseType {

    let toiletRepository: ToiletRepositoryType = Repositories.toiletRepository
    let mapper = Mapper.self

    func execute(id: String) -> Observable<ToiletPresentable> {
      toiletRepository.listen(id: id).map({ entity in
        self.mapper.Toilet.convert(toilet: entity)
      })
    }
  }
}

protocol GetToiletUseCaseType {

}

extension ToiletUseCase {
  struct GetToiletUseCase {

    let toiletRepository: ToiletRepositoryType = Repositories.toiletRepository
    let mapper = Mapper.self

    func execute(id: String) -> Single<ToiletPresentable> {
      toiletRepository.fetch(id: id).map({ entity in
        self.mapper.Toilet.convert(toilet: entity)
      })
    }
  }
}

protocol SearchToiletFromCoordinateUsecaseType {
  func execute(latitude: Double, longitude: Double) -> Observable<ToiletPresentable>
}

extension ToiletUseCase {
  struct SearchToiletFromCoordinateUsecase: SearchToiletFromCoordinateUsecaseType {

    init(
      toiletRepository: ToiletRepositoryType = Repositories.toiletRepository,
      mapper: Mapper.Type = Mapper.self
    ) {
      self.toiletRepository = toiletRepository
      self.mapper = mapper
    }

    let toiletRepository: ToiletRepositoryType
    let mapper: Mapper.Type

    func execute(latitude: Double, longitude: Double) -> Observable<ToiletPresentable> {
      toiletRepository.fetchToilet(
        latitude: latitude,
        longitude: longitude,
        useCache: true
      )
      .compactMap({ $0 })
      .map({ toilet in
        self.mapper.Toilet.convert(toilet: toilet)
      })
    }
  }

}

protocol ObserveAllToiletUseCaseType {
  func execute() -> Observable<[ToiletPresentable]>
}

extension ToiletUseCase {
  struct ObserveAllToiletUseCase: ObserveAllToiletUseCaseType {

    init(
      toiletRepository: ToiletRepositoryType = Repositories.toiletRepository,
      mapper: Mapper.Type = Mapper.self
    ) {
      self.toiletRepository = toiletRepository
      self.mapper = mapper
    }

    let toiletRepository: ToiletRepositoryType
    let mapper: Mapper.Type

    func execute() -> Observable<[ToiletPresentable]> {

      toiletRepository.toiletsObservable
        .map({ toilets in
          toilets.map({ toilet in
            self.mapper.Toilet.convert(toilet: toilet)
          })
        })
    }
  }
}

protocol ObserveNearToiletsUseCaseType {
  func execute() -> Observable<[ToiletPresentable]>
}

extension ToiletUseCase {
  struct ObserveNearToiletsUseCase: ObserveNearToiletsUseCaseType {

    init(
      toiletRepository: ToiletRepositoryType = Repositories.toiletRepository,
      mapper: Mapper.Type = Mapper.self
    ) {
      self.toiletRepository = toiletRepository
      self.mapper = mapper
    }

    let distance: Double = 500

    let toiletRepository: ToiletRepositoryType
    let mapper: Mapper.Type

    func execute() -> Observable<[ToiletPresentable]> {
      fatalError()
    }
  }
}

protocol ObserveCreatedToiletsUseCaseType {
  func execute() -> Observable<[ToiletPresentable]>
}

extension ToiletUseCase {

  struct ObserveCreatedToiletsUseCase: ObserveCreatedToiletsUseCaseType {

    internal init(
      toiletRepository: ToiletRepositoryType = Repositories.toiletRepository,
      mapper: Mapper.Type = Mapper.self
    ) {
      self.toiletRepository = toiletRepository
      self.mapper = mapper
    }

    let toiletRepository: ToiletRepositoryType
    let mapper: Mapper.Type

    func execute() -> Observable<[ToiletPresentable]> {
      toiletRepository.createdToiletsObservable.map({ (toilets: [Entity.Toilet]) in
        toilets.map({ toilet in
          self.mapper.Toilet.convert(toilet: toilet)
        })
      })
      .asObservable()
    }
  }
}

protocol GetRoutesUseCaseType {
  func execute(
    from source: CLLocationCoordinate2D,
    to destination: CLLocationCoordinate2D,
    shouldRequestAlternateRoutes: Bool,
    transportType: MKDirectionsTransportType
  ) -> Single<[MKRoute]>
}

extension ToiletUseCase {
  struct GetRoutesUseCase: GetRoutesUseCaseType {

    func execute(
      from source: CLLocationCoordinate2D,
      to destination: CLLocationCoordinate2D,
      shouldRequestAlternateRoutes: Bool = false,
      transportType: MKDirectionsTransportType = .walking
    ) -> Single<[MKRoute]> {
      return Single<[MKRoute]>.create { (singleEvent) -> Disposable in
        let request = MKDirections.Request()
        request.source = MKMapItem(
          placemark: MKPlacemark(coordinate: source)
        )
        request.destination = MKMapItem(
          placemark: MKPlacemark(coordinate: destination)
        )
        request.requestsAlternateRoutes = shouldRequestAlternateRoutes
        request.transportType = transportType

        let directions = MKDirections(request: request)
        if directions.isCalculating {
          directions.cancel()
        }
        directions.calculate { (response, error) in
          if let error = error {
            singleEvent(.failure(error))
            return
          }
          guard let response = response else {
            return
          }
          var routes: [MKRoute] = []
          for route in response.routes {
            routes.append(route)
          }
          singleEvent(.success(routes))
        }
        return Disposables.create()
      }
    }
  }
}

protocol OpenToiletInDefaultMapUseCase {
  func execute(toilet: ToiletPresentable)
}

extension ToiletUseCase {
  struct OpenToiletInDefaultMap: OpenToiletInDefaultMapUseCase {
    func execute(toilet: ToiletPresentable) {
      let urlStr = "comgooglemaps://?daddr=\(toilet.latitude),\(toilet.longitude)&directionsmode=walking&zoom=14&views=traffic"
      guard let url = URL(string: urlStr) else {
        return
      }
      UIApplication.shared.open(url)
    }
  }
}
