//
//  ToiletRefGenerator.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/02/19.
//

import CoreLocation
import FirebaseFirestore
import Foundation
import RxRelay
import RxSwift

protocol ToiletRefGeneratorType {
  func generate(
    at coordinate: CLLocationCoordinate2D
  ) -> Single<ToiletRefGenerator.Response>
}

class ToiletRefGenerator: ToiletRefGeneratorType {

  private let toiletRepository: ToiletRepositoryType = Repositories.toiletRepository

  typealias Response = (ref: DocumentReference, isNew: Bool)

  func generate(at coordinate: CLLocationCoordinate2D) -> Single<Response> {
    .create { [weak self] (singleEvent) -> Disposable in
      guard let self = self else {
        return Disposables.create()
      }
      let currentToilets = self.toiletRepository.toiles
      if let sameLocationToilet =
        currentToilets
        .first(where: { toilet in
          let toiletLocation = CLLocationCoordinate2D(
            latitude: toilet.latitude,
            longitude: toilet.longitude
          )
          let annotationLocation = coordinate

          return toiletLocation == annotationLocation
        }),
        let ref = sameLocationToilet.ref
      {
        singleEvent(.success((ref, false)))
        return Disposables.create()
      }

      let newRef = Firestore.firestore().collection(Entity.Toilet.collectionName).document()
      singleEvent(.success((newRef, true)))
      return Disposables.create()
    }
  }

}
