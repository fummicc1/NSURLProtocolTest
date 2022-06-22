//
//  ReviewRepository.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/02/10.
//

import EasyFirebaseSwiftFirestore
import Foundation
import RxRelay
import RxSwift

protocol ReviewRepositoryType {
  var reviews: Observable<[Entity.Review]> { get }
  func fetchReviews(of toilet: Entity.Toilet) -> Single<[Entity.Review]>
  func listenReviews(of user: Entity.User) -> Observable<[Entity.Review]>
  func fetchReview(of user: Entity.User) -> Single<[Entity.Review]>
  func create(review: Entity.Review, of toilet: Entity.Toilet) -> Single<Void>
  func update(review: Entity.Review, of toilet: Entity.Toilet) -> Single<Void>
  func clearMyReviews()
}

class ReviewRepository: ReviewRepositoryType {

  static let shared: ReviewRepositoryType = Repositories.reviewRepository

  init(
    firestore: FirestoreClient
  ) {
    self.firestore = firestore
  }

  private let firestore: FirestoreClient

  private let myReviewsRelay: BehaviorRelay<[Entity.Review]> = .init(value: [])

  var reviews: Observable<[Entity.Review]> {
    myReviewsRelay.asObservable().catchAndReturn([])
  }

  func create(review: Entity.Review, of toilet: Entity.Toilet) -> Single<Void> {
    Single.create { [weak self] (singleEvent) -> Disposable in
      guard let parentDocumentID = toilet.ref?.documentID else {
        return Disposables.create()
      }
      let id = review.ref?.documentID
      var review = review
      review.ref = nil
      self?.firestore.create(
        review,
        documentId: id,
        parent: parentDocumentID,
        superParent: nil,
        success: { ref in
          singleEvent(.success(()))
        },
        failure: { error in
          singleEvent(.failure(error))
        })
      return Disposables.create()
    }
  }

  func update(review: Entity.Review, of toilet: Entity.Toilet) -> Single<Void> {
    Single.create { [weak self] singleEvent in
      guard let parentDocumentID = toilet.ref?.documentID else {
        return Disposables.create()
      }
      self?.firestore.update(
        review,
        parent: parentDocumentID,
        superParent: nil,
        success: {
          singleEvent(.success(()))
        },
        failure: { error in
          singleEvent(.failure(error))
        })
      return Disposables.create()
    }
  }

  func listenReviews(of user: Entity.User) -> Observable<[Entity.Review]> {
    Observable.create { [weak self] (observer) -> Disposable in
      guard let uid = user.uid else {
        return Disposables.create()
      }
      self?.firestore.listenCollectionGroup(
        collectionName: Entity.Review.collectionName,
        filter: FirestoreEqualFilter(fieldPath: "sender_uid", value: uid),
        includeCache: true,
        order: [],
        limit: 50,
        success: { (reviews: [Entity.Review]) in
          self?.myReviewsRelay.accept(reviews)
          observer.onNext(reviews)
        },
        failure: { (error) in
          observer.onError(error)
        })
      return Disposables.create()
    }.share()
  }

  func fetchReview(of user: Entity.User) -> Single<[Entity.Review]> {
    .create { (singleEvent) -> Disposable in

      guard let uid = user.uid else {
        return Disposables.create()
      }

      self.firestore.getCollectionGroup(
        collectionName: Entity.Review.collectionName,
        filter: FirestoreEqualFilter(
          fieldPath: "sender_uid",
          value: uid
        ),
        includeCache: true,
        order: [],
        limit: 30,
        success: { (reviews: [Entity.Review]) in
          singleEvent(.success(reviews))
        },
        failure: { error in
          singleEvent(.failure(error))
        })
      return Disposables.create()
    }
  }

  func fetchReviews(of toilet: Entity.Toilet) -> Single<[Entity.Review]> {
    Single.create { [weak self] (singleEvent) -> Disposable in
      guard let self = self else {
        return Disposables.create()
      }
      guard let ref = toilet.ref else {
        return Disposables.create()
      }
      self.firestore.get(
        parent: ref.documentID,
        superParent: nil,
        filter: [],
        order: [],
        limit: 30
      ) { (reviews: [Entity.Review]) in
        singleEvent(.success(reviews))
      } failure: { (error) in
        if case FirestoreClientError.failedToDecode(let responseData) = error {
          if responseData == nil {
            singleEvent(.success([]))
            return
          }
        }
        singleEvent(.failure(error))
      }

      return Disposables.create()
    }
    .catchAndReturn([])
  }

  func clearMyReviews() {
    myReviewsRelay.accept([])
  }
}
