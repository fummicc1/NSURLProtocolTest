//
//  FirestoreCollcetionName.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/02.
//

import Foundation

enum FirestoreCollcetionName: String {
  #if STAGING
    case toilets = "toilets_staging"
    case users = "users_staging"
    case archivedToilets = "archived_toilets_staging"
    case recentlyToilets = "recently_toilets_staging"
    case reviews = "reviews_staging"
    case privateToilet = "private_toilet_staging"
    case toiletDiaries = "toilet_diaries_staging"
  #elseif DEVELOP
    case toilets = "toilets_develop"
    case users = "users_develop"
    case archivedToilets = "archived_toilets_develop"
    case recentlyToilets = "recently_toilets_develop"
    case reviews = "reviews_develop"
    case privateToilet = "private_toilet_develop"
    case toiletDiaries = "toilet_diaries_develop"
  #else
    case toilets
    case users
    case oldToilets = "Toilets"
    case archivedToilets = "archived_toilets"
    case recentlyToilets = "recently_toilets"
    case reviews
    case privateToilet = "private_toilet"
    case toiletDiaries = "toilet_diaries"
  #endif
}
