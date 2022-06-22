//
//  UIView+getSpecificConstraints.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/03.
//

import Foundation
import UIKit

extension UIView {

  func getConstraints<FirstItem: UIView, SecondItem: UIView>(
    first firstItemType: FirstItem.Type, selfAttribute: Int,
    second secondItemType: (SecondItem.Type)? = nil, selfAnchor: NSLayoutAnchor<AnyObject>? = nil
  ) -> [NSLayoutConstraint] {

    var results: [NSLayoutConstraint] = []

    for constraint in constraints {
      if constraint.firstAttribute.rawValue == selfAttribute, constraint.firstItem is FirstItem {

        var isOK = secondItemType == nil ? true : constraint.secondItem is SecondItem ? true : false

        if isOK {
          results.append(constraint)
          continue
        }

        isOK = selfAnchor == nil ? true : constraint.firstAnchor == selfAnchor ? true : false

        if isOK {
          results.append(constraint)
          continue
        }
      }
    }

    return results

  }

}
