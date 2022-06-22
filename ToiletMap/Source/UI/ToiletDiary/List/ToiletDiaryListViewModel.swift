//
//  ToiletDiaryListViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/08/03.
//

import CoreLocation
import Foundation
import RxRelay
import RxSwift

protocol ToiletDiaryListViewModelType {
  var selectedDate: Observable<Date> { get }
  var diaryList: Observable<[ToiletDiaryFragment]> { get }
  var errorMessage: Observable<String> { get }
  var showEditToiletDiaryViewController: Observable<EditToiletDiaryInitializeParameter> { get }

  func viewDidLoad()
  func didSelectDiary(at indexPath: IndexPath)
  func getCurrentLocation() -> CLLocationCoordinate2D?
}

class ToiletDiaryListViewModel: BaseViewModel {

  private let selectedDateRelay: BehaviorRelay<Date> = .init(value: Date())
  private let diaryListRelay: BehaviorRelay<[ToiletDiaryFragment]> = .init(value: [])
  private let errorRelay: PublishRelay<Error> = .init()
  private let showEditToiletDiaryViewControllerRelay:
    PublishRelay<EditToiletDiaryInitializeParameter> = .init()

  private let dependency: Dependency

  init(dependency: ToiletDiaryListViewModel.Dependency) {
    self.dependency = dependency
    super.init()
  }
}

extension ToiletDiaryListViewModel {
  struct Dependency {
    let syncLocalAndRemoteToiletDiaryUseCase: SyncLocalDiaryWithRemoteUseCase
    let observeListUseCase: ObserveAllToiletDiaryUseCase
    let currentLocationUseCase: GetCurrentLocationUseCaseType
  }
}

extension ToiletDiaryListViewModel: ToiletDiaryListViewModelType {

  var selectedDate: Observable<Date> {
    selectedDateRelay.asObservable()
  }

  var diaryList: Observable<[ToiletDiaryFragment]> {
    diaryListRelay.asObservable()
  }

  var errorMessage: Observable<String> {
    errorRelay.map({ $0.localizedDescription })
  }

  var showEditToiletDiaryViewController: Observable<EditToiletDiaryInitializeParameter> {
    showEditToiletDiaryViewControllerRelay.asObservable()
  }

  func didSelectDiary(at indexPath: IndexPath) {
    let diary = diaryListRelay.value[indexPath.row]
    let parameter = EditToiletDiaryInitializeParameter(toiletDiary: diary)
    showEditToiletDiaryViewControllerRelay.accept(parameter)
  }

  func getCurrentLocation() -> CLLocationCoordinate2D? {
    try? dependency.currentLocationUseCase
      .execute()?
      .coordinate
  }

  func viewDidLoad() {
    dependency.observeListUseCase
      .execute()
      .map({
        $0.compactMap({ $0 as? ToiletDiaryFragment })
      })
      .bind(to: diaryListRelay)
      .disposed(by: disposeBag)

    dependency.syncLocalAndRemoteToiletDiaryUseCase
      .uploadAllLocalDiaryToFirestore()
      .asObservable()
      .subscribe()
      .disposed(by: disposeBag)
  }
}
