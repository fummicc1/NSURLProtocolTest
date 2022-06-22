//
//  ToiletDiaryWeekEventView.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/08/16.
//

import Foundation
import UIKit

struct ToiletDiaryDayEvent {
  let date: Date
  let diaries: [ToiletDiaryPresentable]
}

struct ToiletDiaryWeekEvent {
  let interval: DateInterval
  let dayEvents: [ToiletDiaryDayEvent]
}

class ToiletDiaryWeekEventView: XibView {

  let toiletDiaryWeekEvent: ToiletDiaryWeekEvent

  init(toiletDiaryWeekEvent: ToiletDiaryWeekEvent) {
    self.toiletDiaryWeekEvent = toiletDiaryWeekEvent
    super.init(frame: .zero)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
