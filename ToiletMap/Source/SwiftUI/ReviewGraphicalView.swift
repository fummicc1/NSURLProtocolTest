//
//  ReviewGraphicalView.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/07/21.
//

import Combine
import SwiftUI
import SwiftUICharts

class ReviewValue {
  init(yes: Double, no: Double) {
    self.yes = yes
    self.no = no
  }

  static func zero() -> ReviewValue {
    .init(yes: 0, no: 0)
  }

  static func fromScore(_ score: Double) -> ReviewValue {
    .init(yes: score, no: 100 - score)
  }

  let yes: Double
  let no: Double
}

func buildReviewGraphicalView(
  value: AnyPublisher<ReviewScore, Never>
) -> UIHostingController<ReviewGraphicalView> {

  let hostingController = UIHostingController(
    rootView: ReviewGraphicalView(
      data: value
    )
  )
  return hostingController
}

struct ReviewGraphicalView: View {

  let yes = Legend(color: Color(AppColor.mainColor), label: "はい")
  let no = Legend(color: Color(AppColor.accentColor), label: "いいえ")

  var data: AnyPublisher<ReviewScore, Never>

  @State private var dataState: ReviewScore = .init(
    canUse: 0,
    isFree: 0,
    hasWashlet: 0,
    hasAccessibleRestroom: 0,
    alreadyReviewed: false
  )

  var points: [DataPoint] {
    [
      DataPoint(
        value: dataState.mapToValue(keypath: \.canUse).yes,
        label: "\(Int(dataState.mapToValue(keypath: \.canUse).yes))%",
        legend: Legend(
          color: Color(uiColor: AppColor.textColor),
          label: "存在するか"
        )
      ),
      DataPoint(
        value: dataState.mapToValue(keypath: \.isFree).yes,
        label: "\(Int(dataState.mapToValue(keypath: \.isFree).yes))%",
        legend: Legend(
          color: Color(uiColor: AppColor.mainColor),
          label: "無料で使えるか"
        )
      ),
      DataPoint(
        value: dataState.mapToValue(keypath: \.hasWashlet).yes,
        label: "\(Int(dataState.mapToValue(keypath: \.hasWashlet).yes))%",
        legend: Legend(
          color: Color(uiColor: AppColor.textColor),
          label: "ウォシュレットはあるか"
        )
      ),
      DataPoint(
        value: dataState.mapToValue(keypath: \.hasAccessibleRestroom).yes,
        label: "\(Int(dataState.mapToValue(keypath: \.hasAccessibleRestroom).yes))%",
        legend: Legend(
          color: Color(uiColor: AppColor.mainColor),
          label: "多目的トイレはあるか"
        )
      ),
    ]
  }

  var body: some View {
    return VStack {
      HorizontalBarChartView(dataPoints: points)
        .onReceive(
          data,
          perform: { value in
            dataState = value
          })
    }
    .padding()
  }
}

struct ReviewGraphicalView_Previews: PreviewProvider {

  static let currentValueSubject = CurrentValueSubject<ReviewScore, Never>(
    ReviewScore(
      canUse: 0.3,
      isFree: 0.7,
      hasWashlet: 0.8,
      hasAccessibleRestroom: 0.2,
      alreadyReviewed: false
    )
  )

  static var previews: some View {
    ReviewGraphicalView(
      data: currentValueSubject.eraseToAnyPublisher()
    )
  }
}
