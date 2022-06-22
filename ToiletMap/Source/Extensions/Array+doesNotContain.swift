//
//  Array+doesNotContains.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/06.
//

import Foundation

extension Array where Element: Equatable {
  func doesNotContain(_ element: Element) -> Bool { !contains(element) }
}

extension Array {
  func removeDuplicates<Value: Equatable>(keyPath: KeyPath<Element, Value>) -> [Element] {
    var result = [Element]()

    for element in self {
      if result.contains(where: { e in e[keyPath: keyPath] == element[keyPath: keyPath] }) == false
      {
        result.append(element)
      }
    }

    return result
  }
}
