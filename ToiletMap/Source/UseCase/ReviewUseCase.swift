//
//  ReviewUseCase.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/19.
//

import CoreLocation
import Foundation
import RxRelay
import RxSwift

enum ReviewUseCase {}

protocol CreateReviewUseCaseType {
  func execute(
    toilet: ToiletPresentable,
    canUse: Bool,
    isFree: Bool,
    hasWashlet: Bool,
    hasAccessibleRestroom: Bool
  ) -> Single<Void>
}

extension ReviewUseCase {
  struct CreateReviewUseCase: CreateReviewUseCaseType {

    init(
      toiletRepository: ToiletRepositoryType = Repositories.toiletRepository,
      userRepository: UserRepositoryType = Repositories.userRepository,
      reviewRepository: ReviewRepositoryType = Repositories.reviewRepository,
      toiletRefGenerator: ToiletRefGenerator = ToiletRefGenerator(),
      mapper: Mapper.Type = Mapper.self
    ) {
      self.toiletRepository = toiletRepository
      self.userRepository = userRepository
      self.reviewRepository = reviewRepository
      self.toiletRefGenerator = toiletRefGenerator
      self.mapper = mapper
    }

    enum Error: Swift.Error {
      case noMe
    }

    let toiletRepository: ToiletRepositoryType
    let userRepository: UserRepositoryType
    let reviewRepository: ReviewRepositoryType
    let toiletRefGenerator: ToiletRefGenerator
    let mapper: Mapper.Type

    func execute(
      toilet: ToiletPresentable,
      canUse: Bool,
      isFree: Bool,
      hasWashlet: Bool,
      hasAccessibleRestroom: Bool
    ) -> Single<Void> {
      guard let uid = userRepository.user?.uid else {
        return .error(Error.noMe)
      }
      let senderFragment = UserFragment(uid: uid)

      return toiletRefGenerator.generate(
        at: CLLocationCoordinate2D(
          latitude: toilet.latitude,
          longitude: toilet.longitude
        )
      )
      .flatMap({ (toiletRef, isNew) -> Single<Entity.Toilet> in
        self.toiletRepository.fetch(id: toiletRef.documentID)
      })
      .map({ entity in
        self.mapper.Toilet.convert(toilet: entity)
      })
      .map({ toilet -> ReviewPresentable in
        let fragment = ReviewFragment(
          ref: nil,
          sender: senderFragment,
          canUse: canUse,
          isFree: isFree,
          hasWashlet: hasWashlet,
          hasAccessibleRestroom: hasAccessibleRestroom,
          toilet: toilet,
          createdAt: nil,
          updatedAt: nil
        )
        return fragment
      })
      .map({ fragment in
        try self.mapper.Review.convert(review: fragment)
      })
      .flatMap({ review in
        self.reviewRepository.create(review: review, of: review.toilet!)
      })
    }
  }
}

protocol UpdateReviewUseCaseType {
  func execute(
    toilet: ToiletPresentable,
    review: ReviewPresentable
  ) -> Observable<Void>
}

extension ReviewUseCase {
  struct UpdateReviewUsecase: UpdateReviewUseCaseType {

    enum Error: Swift.Error {
      case noMe
    }

    init(
      toiletRepository: ToiletRepositoryType = Repositories.toiletRepository,
      userRepository: UserRepositoryType = Repositories.userRepository,
      reviewRepository: ReviewRepositoryType = Repositories.reviewRepository,
      toiletRefGenerator: ToiletRefGenerator = ToiletRefGenerator(),
      mapper: Mapper.Type = Mapper.self
    ) {
      self.toiletRepository = toiletRepository
      self.userRepository = userRepository
      self.reviewRepository = reviewRepository
      self.toiletRefGenerator = toiletRefGenerator
      self.mapper = mapper
    }

    let toiletRepository: ToiletRepositoryType
    let userRepository: UserRepositoryType
    let reviewRepository: ReviewRepositoryType
    let toiletRefGenerator: ToiletRefGenerator
    let mapper: Mapper.Type

    func execute(
      toilet: ToiletPresentable,
      review: ReviewPresentable
    ) -> Observable<Void> {
      let toiletEntity = mapper.Toilet.convert(toilet: toilet)

      do {
        let reviewEntity = try mapper.Review.convert(review: review)
        return
          reviewRepository
          .update(review: reviewEntity, of: toiletEntity)
          .asObservable()
      } catch {
        return .error(error)
      }
    }

  }
}

protocol GetReviewListUseCaseType {
  func execute(of toilet: ToiletPresentable) -> Single<[ReviewPresentable]>
  func execute(of user: UserPresentable) -> Single<[ReviewPresentable]>
}

extension ReviewUseCase {
  struct GetReviewListUseCase: GetReviewListUseCaseType {

    enum Error: Swift.Error {
      case noToiletId
    }

    init(
      toiletRepository: ToiletRepositoryType = Repositories.toiletRepository,
      userRepository: UserRepositoryType = Repositories.userRepository,
      reviewRepository: ReviewRepositoryType = Repositories.reviewRepository,
      toiletRefGenerator: ToiletRefGenerator = ToiletRefGenerator(),
      mapper: Mapper.Type = Mapper.self
    ) {
      self.toiletRepository = toiletRepository
      self.userRepository = userRepository
      self.reviewRepository = reviewRepository
      self.toiletRefGenerator = toiletRefGenerator
      self.mapper = mapper
    }

    let toiletRepository: ToiletRepositoryType
    let userRepository: UserRepositoryType
    let reviewRepository: ReviewRepositoryType
    let toiletRefGenerator: ToiletRefGenerator
    let mapper: Mapper.Type

    func execute(of toilet: ToiletPresentable) -> Single<[ReviewPresentable]> {
      let isArchived = toilet.isArchived

      let toiletId: Single<String>

      if isArchived {

        guard let archived = toilet as? ArchivedToiletPresentable,
          let toiletRef = archived.toiletRef
        else {
          assertionFailure()
          return .never()
        }

        toiletId = .just(toiletRef.documentID)
      } else if let toiletRef = toilet.ref {
        toiletId = .just(toiletRef.documentID)
      } else {

        let coordinate = CLLocationCoordinate2D(
          latitude: toilet.latitude,
          longitude: toilet.longitude
        )

        toiletId = toiletRefGenerator.generate(at: coordinate)
          .flatMap({ ref, isNew in
            if isNew {
              var entity = self.mapper.Toilet.convert(toilet: toilet)
              entity.ref = nil
              return self.toiletRepository
                .create(toilet: entity, id: ref.documentID)
                .map({ ref in
                  ref.documentID
                })
            } else {
              return .just(ref.documentID)
            }
          })
      }

      return
        toiletId
        .flatMap({ toiletId in
          self.toiletRepository
            .fetch(id: toiletId)
            .flatMap({ entityToilet in
              self.reviewRepository.fetchReviews(of: entityToilet)
            })
            .map({ reviews in
              try reviews.map({ review in
                try self.mapper.Review.convert(review: review)
              })
            })
        })
    }

    func execute(of user: UserPresentable) -> Single<[ReviewPresentable]> {
      do {
        return try mapper.User.convert(user: user)
          .flatMap({ entity in
            self.reviewRepository.fetchReview(of: entity)
          })
          .map({ reviews in
            try reviews.map({ review in
              try self.mapper.Review.convert(review: review)
            })
          })
      } catch {
        return .error(error)
      }
    }
  }
}

protocol ObserveReviewListUseCaseType {
  func execute(of user: UserPresentable) -> Observable<[ReviewPresentable]>
}

extension ReviewUseCase {

  struct ObserveReviewListUseCase: ObserveReviewListUseCaseType {

    init(
      reviewRepository: ReviewRepositoryType = ReviewRepository.shared,
      mapper: Mapper.Type = Mapper.self
    ) {
      self.reviewRepository = reviewRepository
      self.mapper = mapper
    }

    let reviewRepository: ReviewRepositoryType
    let mapper: Mapper.Type

    func execute(of user: UserPresentable) -> Observable<[ReviewPresentable]> {
      do {
        return try mapper.User.convert(user: user)
          .asObservable()
          .flatMap({ entity in
            reviewRepository.listenReviews(of: entity)
          })
          .map({ reviews in
            try reviews.map({ review in
              try self.mapper.Review.convert(review: review)
            })
          })
      } catch {
        return .error(error)
      }
    }
  }
}

protocol CalculateReviewScoreTye {
  func execute(reviews: [ReviewPresentable]) -> Single<ReviewScore?>
}

extension ReviewUseCase {
  struct CalculateReviewScore: CalculateReviewScoreTye {

    init(
      toiletRepository: ToiletRepositoryType = Repositories.toiletRepository,
      userRepository: UserRepositoryType = Repositories.userRepository,
      reviewRepository: ReviewRepositoryType = Repositories.reviewRepository,
      mapper: Mapper.Type = Mapper.self
    ) {
      self.toiletRepository = toiletRepository
      self.userRepository = userRepository
      self.reviewRepository = reviewRepository
      self.mapper = mapper
    }

    let toiletRepository: ToiletRepositoryType
    let userRepository: UserRepositoryType
    let reviewRepository: ReviewRepositoryType
    let mapper: Mapper.Type

    func execute(reviews: [ReviewPresentable]) -> Single<ReviewScore?> {
      do {
        let reviewEntities = try reviews.map({ review in
          try mapper.Review.convert(review: review)
        })
        return try .just(mapper.Reviews.convert(reviews: reviewEntities))
      } catch {
        return .error(error)
      }
    }
  }
}

protocol ValidateWhetherUserNotReviewedYetUseCaseType {
  func execute(reviews: [ReviewPresentable]?) -> Single<Bool>
}

extension ReviewUseCase {

  struct ValidateWhetherUserNotReviewedYetUseCase: ValidateWhetherUserNotReviewedYetUseCaseType {

    enum Error: Swift.Error {
      case toiletIdNotFound
    }

    init(
      toiletRepository: ToiletRepositoryType = Repositories.toiletRepository,
      userRepository: UserRepositoryType = Repositories.userRepository,
      reviewRepository: ReviewRepositoryType = Repositories.reviewRepository,
      mapper: Mapper.Type = Mapper.self
    ) {
      self.toiletRepository = toiletRepository
      self.userRepository = userRepository
      self.reviewRepository = reviewRepository
      self.mapper = mapper
    }

    let toiletRepository: ToiletRepositoryType
    let userRepository: UserRepositoryType
    let reviewRepository: ReviewRepositoryType
    let mapper: Mapper.Type

    func execute(reviews: [ReviewPresentable]?) -> Single<Bool> {

      guard let uid = userRepository.user?.uid else {
        return .just(false)
      }

      if let reviews = reviews, reviews.isNotEmpty {
        let isReviewed = reviews.contains(where: { review in
          review.sender.uid == uid
        })
        return .just(!isReviewed)
      }
      return .just(true)
    }

  }
}
