//
//  ToiletCardView.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/04/20.
//

import SwiftUI

struct ToiletCardView: View {

  @ObservedObject var viewModel: ToiletCardViewModel

  var body: some View {
    Text("Hello, World!")
  }
}

struct ToiletCardView_Previews: PreviewProvider {
  static var previews: some View {
    ToiletCardView(
      viewModel: ToiletCardViewModel(
        toilet: ToiletFragment(
          sender: nil,
          name: "Test",
          detail: "Test Detail",
          latitude: 40,
          longitude: 130,
          ref: nil,
          createdAt: nil,
          updatedAt: nil,
          isArchived: false)
      )
    )
  }
}
