//
//  SearchViewModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/07.
//

import Foundation
import MapKit
import RxCocoa
import RxSwift

protocol SearchViewModelType {
  var searchResultAnnotations: Observable<[MapAnnotation]> { get }
  var searchToken: Observable<UISearchBar.SearchTokenModel> { get }
  var searchStatus: Observable<SearchViewModel.SearchStatus> { get }
  var heightStatus: Observable<SearchViewControllerHeightStatus> { get }

  func update(text: String)
  func startSearch()
  func didTapSearchToken(tag: Int)
  func didTapHeightStatusToggleButton()
}

enum SearchViewControllerHeightStatus {
  case shrink
  case expand
  case minimum
}

class SearchViewModel: BaseViewModel, SearchViewModelType {

  enum SearchStatus {
    case idle
    case searching
  }

  private let searchResultAnnotationsRelay: BehaviorRelay<[MapAnnotation]> = .init(value: [])
  private let searchTokenRelay: PublishRelay<UISearchBar.SearchTokenModel> = .init()
  private let searchStatusRelay: BehaviorRelay<SearchStatus> = .init(value: .idle)
  private let searchTextRelay: BehaviorRelay<String> = .init(value: "")
  private let heightStatusRelay: BehaviorRelay<SearchViewControllerHeightStatus> = .init(
    value: .shrink)
  private let errorMessageRelay: PublishRelay<String> = .init()

  var searchResultAnnotations: Observable<[MapAnnotation]> {
    searchResultAnnotationsRelay.asObservable().share()
  }

  var searchStatus: Observable<SearchViewModel.SearchStatus> {
    searchStatusRelay.asObservable()
  }

  var searchToken: Observable<UISearchBar.SearchTokenModel> {
    searchTokenRelay.asObservable()
  }

  var heightStatus: Observable<SearchViewControllerHeightStatus> {
    heightStatusRelay.asObservable()
  }

  private let useCase = UseCase()

  struct UseCase {
    let searchMapItemUseCase = MapItemUseCase.SearchMapItemFromCurrentLocationUseCase()
    let searchMapItemFromDataStoreUseCase = MapItemUseCase.SearchMapItemFromDataStore()
  }

  func update(text: String) {
    searchTextRelay.accept(text)
    startSearch()
  }

  override init() {
    super.init()
    searchTextRelay.accept("トイレ")
    startSearch()
  }

  func startSearch() {

    let word = searchTextRelay.value
    if word.isEmpty {
      return
    }

    // Start Searching
    searchStatusRelay.accept(.searching)

    Observable.combineLatest(
      useCase
        .searchMapItemFromDataStoreUseCase
        .execute(word: word)
        .map({ items in items.map({ $0 as MapAnnotation }) })
        .asObservable(),
      useCase
        .searchMapItemUseCase
        .execute(word: word)
        .map({ items in items.map({ $0 as MapAnnotation }) })
        .asObservable()
    )
    .map({ (fromDB, fromMKSearch) in
      fromDB + fromMKSearch
    })
    .catch({ [weak self] error in
      self?.errorMessageRelay.accept(error.localizedDescription)
      self?.searchStatusRelay.accept(.idle)
      return .never()
    })
    .subscribe(onNext: { [weak self] annotations in
      let all =
        annotations
        .removeDuplicates(keyPath: \.toilet.coordinate)
        .map { annotation -> MapAnnotation in
          annotation.isHighlight = true
          return annotation
        }
      self?.searchResultAnnotationsRelay.accept(all)
      self?.searchStatusRelay.accept(.idle)
    })
    .disposed(by: disposeBag)
  }

  func didTapSearchToken(tag: Int) {
    let model = UISearchBar.SearchTokenModel(tag: tag)
    searchTokenRelay.accept(model)
    searchTextRelay.accept(model.localizedWord)
  }

  func didTapHeightStatusToggleButton() {
    let current = heightStatusRelay.value
    let next: SearchViewControllerHeightStatus
    switch current {
    case .shrink:
      next = .minimum
    case .expand:
      next = .shrink
    case .minimum:
      next = .expand
    }
    heightStatusRelay.accept(next)
  }
}
