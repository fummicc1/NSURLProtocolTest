//
//  MapItemRepository.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/02/09.
//

import AlgoliaSearchClient
import EasyFirebaseSwiftFirestore
import FirebaseFirestore
import Foundation
import MapKit
import RxRelay
import RxSwift

protocol MapItemRepositoryType {
  var searchedMapItems: Observable<[MKMapItem]> { get }
  func search(with word: String, center: CLLocationCoordinate2D, radius: CLLocationDegrees)
    -> Single<[MKMapItem]>
  func search(with word: String, central: CLLocationCoordinate2D, limit: Int) -> Observable<
    [ToiletPresentable]
  >
  func reload()
}

class MapItemRepository: MapItemRepositoryType {

  static let shared: MapItemRepositoryType = Repositories.mapItemRepository

  private let algoliaSearchClient = AlgoliaSearchClient.SearchClient(
    appID: "APPID",
    apiKey: "APIKEY"
  )
  private let toiletMapper: Mapper.Toilet.Type = Mapper.Toilet.self
  private let firestoreClient: FirestoreClient
  private let searchedMapItemsRelay: BehaviorRelay<[MKMapItem]> = .init(value: [])

  var searchedMapItems: Observable<[MKMapItem]> {
    searchedMapItemsRelay.asObservable()
  }

  init(
    firestore: FirestoreClient
  ) {
    self.firestoreClient = firestore
  }

  func search(with word: String, center: CLLocationCoordinate2D, radius: CLLocationDegrees)
    -> Single<[MKMapItem]>
  {
    Single.create { (singleEvent) -> Disposable in
      let region = MKCoordinateRegion(
        center: center, latitudinalMeters: radius, longitudinalMeters: radius)
      let request = MKLocalSearch.Request()
      request.region = region
      request.naturalLanguageQuery = word
      let query = MKLocalSearch(request: request)
      query.start { (response, error) in
        if let error = error {
          singleEvent(.failure(error))
          return
        }
        guard let response = response else {
          singleEvent(.success([]))
          return
        }
        let items = response.mapItems
        self.searchedMapItemsRelay.accept(items)
        singleEvent(.success(items))
      }
      return Disposables.create()
    }
  }

  func search(with word: String, central: CLLocationCoordinate2D, limit: Int) -> Observable<
    [ToiletPresentable]
  > {
    let index = algoliaSearchClient.index(withName: "toilet_search")
    return Single<[AlgoliaToiletEntity]>.create { observer -> Disposable in
      var option = RequestOptions()
      option.setParameter(String(limit), forKey: "limit")
      index.search(
        query: Query(word)
          .set(
            \.aroundLatLng,
            to: Point(latitude: central.latitude, longitude: central.longitude)
          ),
        requestOptions: option
      ) { result in
        switch result {
        case .failure(let error):
          observer(.failure(error))

        case .success(let response):
          do {
            let encoded = try JSONEncoder().encode(response.hits.map(\.object))
            let decoder = JSONDecoder()
            let algoliaToilets: [AlgoliaToiletEntity] =
              try decoder
              .decode([Throwable<AlgoliaToiletEntity>].self, from: encoded)
              .compactMap({ try? $0.result.get() })
            observer(.success(algoliaToilets))
          } catch {
            print(error)
            observer(.failure(error))
          }
        }
      }
      return Disposables.create()
    }.asObservable().flatMap { algoliaToilets -> Observable<[ToiletPresentable]> in
      let singles = algoliaToilets.map { algoliaToilet -> Observable<Entity.Toilet> in
        let latFilter = FirestoreEqualFilter(
          fieldPath: "latitude", value: algoliaToilet.latitude
        )
        let longFilter = FirestoreEqualFilter(
          fieldPath: "longitude", value: algoliaToilet.longitude
        )
        return Single<Entity.Toilet?>.create { singleEvent in
          self.firestoreClient.get(
            filter: [
              latFilter,
              longFilter,
            ],
            order: [], limit: 1
          ) { (models: [Entity.Toilet]) in
            guard let model = models.first else {
              singleEvent(.success(nil))
              return
            }
            singleEvent(.success(model))
          } failure: { error in
            singleEvent(.failure(error))
          }
          return Disposables.create()
        }.compactMap({ $0 }).asObservable()
      }
      let asyncSequence = Observable.from(singles)
        .merge()
        .toArray()
      let fragments = asyncSequence.map({ toilets in
        toilets.map({ self.toiletMapper.convert(toilet: $0) })
      })
      return fragments.asObservable()
    }
  }

  func reload() {
    searchedMapItemsRelay.accept(searchedMapItemsRelay.value)
  }
}

struct Throwable<T: Decodable>: Decodable {
  let result: Result<T, Error>

  init(from decoder: Decoder) throws {
    result = Result(catching: { try T(from: decoder) })
  }
}

struct AlgoliaToiletEntity: Codable {
  let latitude: Double
  let longitude: Double
}
