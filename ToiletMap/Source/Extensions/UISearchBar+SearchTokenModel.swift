//
//  UISearchBar+SearchTokenModel.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/03.
//

import Foundation
import RxCocoa
import RxSwift
import UIKit

extension UISearchBar {
  enum SearchTokenModel {
    case station
    case fastfood
    case other(String)

    var localizedWord: String {
      switch self {
      case .station:
        return "駅"
      case .fastfood:
        return "ファーストフード"
      case .other(let word):
        return word
      }
    }

    var iconImage: UIImage? {
      UIImage(systemName: "magnifyingglass")
    }

    init(tag: Int) {
      if tag == 1 {
        self = .station
      } else if tag == 2 {
        self = .fastfood
      } else {
        self = .other("")
      }

    }
  }
}

extension Reactive where Base: UISearchTextField {

  var tokens: Observable<[UISearchToken]> {
    let tokens = observe([UISearchToken].self, #keyPath(UISearchTextField.tokens))
    return tokens.flatMap(Observable.from(optional:))
  }

}
