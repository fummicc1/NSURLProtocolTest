//
//  UserPresentable.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/18.
//

import Foundation

protocol UserPresentable {
  var uid: String { get }
}

struct UserFragment: UserPresentable {
  var uid: String
}
