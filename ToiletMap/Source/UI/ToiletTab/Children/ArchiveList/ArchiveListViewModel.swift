//
//  ArchiveListViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/03/28.
//

import Foundation
import RxCocoa
import RxSwift

protocol ArchiveListViewModelOutput {
  var archiveList: Observable<[ArchivedToiletPresentable]> { get }
  var archiveListData: [ArchivedToiletPresentable] { get }
}

class ArchiveListViewModel: BaseViewModel, ArchiveListViewModelOutput {
  var archiveList: Observable<[ArchivedToiletPresentable]> {
    archivedListRelay.asObservable()
  }
  var archiveListData: [ArchivedToiletPresentable] {
    archivedListRelay.value
  }

  private let archivedListRelay: BehaviorRelay<[ArchivedToiletPresentable]> = .init(value: [])

  struct UseCase {
    let observeArchivedToilets = ArchivedToiletUseCase.ObserveArchivedToiletsUseCase()
  }

  let useCase = UseCase()

  override init() {
    super.init()
    useCase.observeArchivedToilets
      .execute()
      .bind(to: archivedListRelay)
      .disposed(by: disposeBag)
  }
}
