//
//  ToiletDiaryDayResultFragment.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/08/17.
//

import Foundation

protocol ToiletDiaryDayResultPresentable {
  var diaries: [ToiletDiaryPresentable] { get }
  var date: Date { get }
  var mostUsedToilet: ToiletPresentable? { get }
}
