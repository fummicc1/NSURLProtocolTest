//
//  ToiletCardViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/04/20.
//

import Foundation
import RxRelay
import RxSwift
import SwiftUI

class ToiletCardViewModel: ObservableObject {

  @Published var toilet: ToiletPresentable
  @Published var shouldMoveToDetail: Bool = false

  private let createArchivedToilet: ArchivedToiletUseCase.CreateArchivedToiletUseCase = .init()
  private let deleteArchivedToilet: ArchivedToiletUseCase.DeleteArchivedToiletUseCase = .init()

  private let disposeBag: DisposeBag = .init()

  public init(toilet: ToiletPresentable) {
    self.toilet = toilet
  }

  func toggleArchiveState() {
    let isArchived = toilet.isArchived

    if isArchived {

      guard let id = toilet.ref?.documentID else {
        assertionFailure("No Document ID")
        return
      }

      deleteArchivedToilet
        .execute(archivedId: id)
        .subscribe()
        .disposed(by: disposeBag)
    } else {
      createArchivedToilet
        .execute(from: toilet)
        .subscribe()
        .disposed(by: disposeBag)
    }
  }
}
