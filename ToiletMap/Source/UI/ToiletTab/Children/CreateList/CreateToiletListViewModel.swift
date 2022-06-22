//
//  CreateToiletListViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/13.
//

import Foundation
import RxRelay
import RxSwift

protocol CreateToiletListViewModelType {
  var createdToiletList: Observable<[ToiletPresentable]> { get }
}

class CreateToiletListViewModel: BaseViewModel {

  private let useCase = UseCase()

  private let createdToiletListRelay: BehaviorRelay<[ToiletPresentable]> = .init(value: [])

  struct UseCase {
    let createdToilets = ToiletUseCase.ObserveCreatedToiletsUseCase()
  }

  override init() {
    super.init()
    useCase.createdToilets
      .execute()
      .bind(to: createdToiletListRelay)
      .disposed(by: disposeBag)
  }
}

extension CreateToiletListViewModel: CreateToiletListViewModelType {
  var createdToiletList: Observable<[ToiletPresentable]> {
    createdToiletListRelay.asObservable().catchAndReturn([])
  }
}
