//
//  MeFragment.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/18.
//

import Foundation

protocol MePresentable: UserPresentable {
  var uid: String { get }
  var createToiletList: [ToiletPresentable] { get }
  var archiveToiletList: [ToiletPresentable] { get }
  var homeToilet: HomeToiletPresentable? { get }
  var email: String? { get }
  var status: Entity.User.Status { get }
}

struct MeFragment: MePresentable, UserPresentable {

  var createToiletList: [ToiletPresentable]
  var archiveToiletList: [ToiletPresentable]
  var homeToilet: HomeToiletPresentable?

  var uid: String
  var email: String?
  var status: Entity.User.Status
}
