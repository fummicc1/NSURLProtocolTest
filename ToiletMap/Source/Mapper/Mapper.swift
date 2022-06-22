//
//  Mapper.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/18.
//

import FirebaseFirestore
import Foundation
import RxRelay
import RxSwift

enum Mapper {

  struct Toilet {

    enum Error: Swift.Error {
      case senderNil
      case noDocumentReference
    }

    static func convert(toilet: Entity.Toilet) -> ToiletPresentable {
      let senderUid = toilet.sender
      let senderPresentable: UserPresentable?
      if let senderUid = senderUid {
        senderPresentable = UserFragment(uid: senderUid)
      } else {
        senderPresentable = nil
      }
      return ToiletFragment(
        sender: senderPresentable,
        name: toilet.name,
        detail: toilet.detail,
        latitude: toilet.latitude,
        longitude: toilet.longitude,
        ref: toilet.ref,
        isArchived: false
      )
    }

    static func convert(toilet: ToiletPresentable) -> Entity.Toilet {
      let createdAt = toilet.createdAt == nil ? nil : Timestamp(date: toilet.createdAt!)
      let updatedAt = toilet.updatedAt == nil ? nil : Timestamp(date: toilet.updatedAt!)
      let toiletEntity = Entity.Toilet(
        sender: toilet.sender?.uid,
        name: toilet.name,
        detail: toilet.detail,
        latitude: toilet.latitude,
        longitude: toilet.longitude,
        ref: toilet.ref,
        createdAt: createdAt,
        updatedAt: updatedAt
      )
      return toiletEntity
    }
  }

  struct ArchivedToilet {

    enum Error: Swift.Error {
      case senderNil
    }

    private let toiletRepository: ToiletRepositoryType = Repositories.toiletRepository
    private let userRepository: UserRepositoryType = Repositories.userRepository

    static func convert(toilet: Entity.ArchivedToilet) throws -> ArchivedToiletPresentable {
      guard let senderUid = toilet.sender else {
        throw Error.senderNil
      }
      let createdAt = toilet.createdAt == nil ? nil : toilet.createdAt!.dateValue()
      let updatedAt = toilet.updatedAt == nil ? nil : toilet.updatedAt!.dateValue()
      let senderFragment = UserFragment(uid: senderUid)
      return ArchivedToiletFragment(
        toiletRef: toilet.origin,
        sender: senderFragment,
        name: toilet.name,
        detail: toilet.detail,
        latitude: toilet.latitude,
        longitude: toilet.longitude,
        ref: toilet.ref,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isArchived: true
      )
    }

    static func convert(toilet: ArchivedToiletPresentable) -> Entity.ArchivedToilet {
      let createdAt = toilet.createdAt == nil ? nil : Timestamp(date: toilet.createdAt!)
      let updatedAt = toilet.updatedAt == nil ? nil : Timestamp(date: toilet.updatedAt!)
      return Entity.ArchivedToilet(
        origin: toilet.toiletRef,
        ref: toilet.ref,
        createdAt: createdAt,
        updatedAt: updatedAt,
        sender: toilet.sender?.uid,
        name: toilet.name,
        detail: toilet.detail,
        latitude: toilet.latitude,
        longitude: toilet.longitude,
        memo: nil
      )
    }
  }

  struct HomeToilet {
    enum Error: Swift.Error {
      case noSender
      case notMyHome
      case othersHomeToilet
    }

    private static let authRepository: AuthRepositoryType = Repositories.authRepository
    private static let userRepository: UserRepositoryType = Repositories.userRepository

    static func convert(homeToilet: Entity.HomeToilet) throws -> HomeToiletPresentable {

      guard let senderUid = homeToilet.sender else {
        throw Error.noSender
      }

      let me = userRepository.user

      guard let me = me, me.uid == senderUid else {
        throw Error.othersHomeToilet
      }

      let senderPresentable = try Mapper.User.convert(user: me)

      return HomeToiletFragment(
        sender: senderPresentable,
        name: homeToilet.name,
        detail: homeToilet.detail,
        latitude: homeToilet.latitude,
        longitude: homeToilet.longitude,
        ref: nil,
        createdAt: nil,
        updatedAt: nil
      )
    }

    static func convert(presentable: HomeToiletPresentable) throws -> Single<Entity.HomeToilet> {
      guard let sender = presentable.sender else {
        throw Error.noSender
      }
      let entity = Entity.HomeToilet(
        sender: sender.uid,
        name: presentable.name,
        detail: presentable.detail,
        latitude: presentable.latitude,
        longitude: presentable.longitude
      )
      return .just(entity)
    }
  }

  struct Me {
    enum Error: Swift.Error {
      case noUid
      case noMe
      case invalidUser(String, String)
    }

    private static let userRepository: UserRepositoryType = Repositories.userRepository
    private static let toiletRepository: ToiletRepositoryType = Repositories.toiletRepository
    private static let authRepository: AuthRepositoryType = Repositories.authRepository

    static func convert(user: Entity.User) throws -> MePresentable {
      guard let uid = user.uid else {
        throw Error.noUid
      }
      let created = toiletRepository.createdToilets.map({ toilet in
        Toilet.convert(toilet: toilet)
      })

      let archived = toiletRepository.archivedToilets.compactMap({ toilet in
        try? ArchivedToilet.convert(toilet: toilet)
      })

      var homeToilet: HomeToiletPresentable? = nil

      if let home = user.homeToilet {
        homeToilet = try Mapper.HomeToilet.convert(homeToilet: home) as HomeToiletPresentable
      }

      guard let currentUser = authRepository.userValue else {
        throw Error.noUid
      }

      return MeFragment(
        createToiletList: created,
        archiveToiletList: archived,
        homeToilet: homeToilet,
        uid: uid,
        email: currentUser.email,  // me is authUser.
        status: currentUser.status
      )
    }

    static func convert(me: MePresentable) throws -> Single<Entity.User> {
      guard let meEntity = userRepository.user else {
        throw Error.noMe
      }
      let isSame = me.uid == meEntity.uid
      if isSame == false {
        return userRepository.get(uid: me.uid)
      }
      return .just(meEntity)
    }
  }

  struct User {
    enum Error: Swift.Error {
      case noUid
    }

    private static let userRepository: UserRepositoryType = Repositories.userRepository

    static func convert(user: Entity.User) throws -> UserPresentable {
      guard let uid = user.uid else {
        throw Error.noUid
      }
      return UserFragment(uid: uid)
    }

    static func convert(user: UserPresentable) throws -> Single<Entity.User> {
      let uid = user.uid
      return userRepository.get(uid: uid)
    }
  }

  struct Review {
    enum Error: Swift.Error {

    }

    private static let userRepository: UserRepositoryType = Repositories.userRepository
    private static let reviewRepository: ReviewRepositoryType = Repositories.reviewRepository

    static func convert(review: Entity.Review) throws -> ReviewPresentable {
      let senderUid = review.senderUID

      let senderFragment = UserFragment(uid: senderUid)

      let toilet: ToiletPresentable?

      if let _toilet = review.toilet {
        let toiletPresentable = Toilet.convert(toilet: _toilet)
        toilet = toiletPresentable
      } else {
        toilet = nil
      }

      let createdAt = review.createdAt == nil ? nil : review.createdAt!.dateValue()
      let updatedAt = review.updatedAt == nil ? nil : review.updatedAt!.dateValue()

      return ReviewFragment(
        ref: review.ref,
        sender: senderFragment,
        canUse: review.canUse,
        isFree: review.isFree,
        hasWashlet: review.hasWashlet,
        hasAccessibleRestroom: review.hasAccessibleRestroom,
        toilet: toilet,
        createdAt: createdAt,
        updatedAt: updatedAt
      )
    }

    static func convert(review: ReviewPresentable) throws -> Entity.Review {
      let createdAt = review.createdAt == nil ? nil : Timestamp(date: review.createdAt!)
      let updatedAt = review.updatedAt == nil ? nil : Timestamp(date: review.updatedAt!)

      let toilet: Entity.Toilet?

      if let _toilet = review.toilet {
        let entity = Toilet.convert(toilet: _toilet)
        toilet = entity
      } else {
        toilet = nil
      }

      return Entity.Review(
        senderUID: review.sender.uid,
        canUse: review.canUse,
        isFree: review.isFree,
        hasWashlet: review.hasWashlet,
        hasAccessibleRestroom: review.hasAccessibleRestroom,
        ref: review.ref,
        createdAt: createdAt,
        updatedAt: updatedAt,
        toilet: toilet
      )
    }
  }

  struct Reviews {

    enum Error: Swift.Error {
      case noMe
    }

    private static let userRepository: UserRepositoryType = Repositories.userRepository

    static func convert(reviews: [Entity.Review]) throws -> ReviewScore? {

      guard let myUid = userRepository.user?.uid else {
        throw Error.noMe
      }

      if reviews.isEmpty {
        return nil
      }

      let canUseCount: Double = Double(reviews.filter({ $0.canUse }).count)
      let isFreeCount: Double = Double(reviews.filter({ $0.isFree }).count)
      let hasWashletCount: Double = Double(reviews.filter({ $0.hasWashlet }).count)
      let hasAccessibleRestroomCount: Double = Double(
        reviews.filter({ $0.hasAccessibleRestroom }).count)

      let total: Double = Double(reviews.count)

      let reviewScore = ReviewScore(
        canUse: canUseCount / total * 100,
        isFree: isFreeCount / total * 100,
        hasWashlet: hasWashletCount / total * 100,
        hasAccessibleRestroom: hasAccessibleRestroomCount / total * 100,
        alreadyReviewed: reviews.map({ $0.senderUID }).doesNotContain(myUid)
      )

      return reviewScore
    }

  }
}
