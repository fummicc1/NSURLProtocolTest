//
//  UIViewController+AlertView.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2019/12/31.
//

import Foundation
import UIKit

extension UIViewController {
  func showSimpleAlert(
    alertStyle: UIAlertController.Style = .alert,
    title: String,
    message: String?,
    buttonTitle: String?,
    buttonStyle: UIAlertAction.Style = .default,
    handler: ((UIAlertAction) -> Void)? = nil,
    secondButtonTitle: String? = nil,
    secondButtonStyle: UIAlertAction.Style? = nil,
    secondButtonHandler: ((UIAlertAction) -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) {

    guard title.isNotEmpty else {
      return
    }

    let alert = UIAlertController(title: title, message: message, preferredStyle: alertStyle)

    if let buttonTitle = buttonTitle {
      alert.addAction(UIAlertAction(title: buttonTitle, style: buttonStyle, handler: handler))
    }

    if let secondButtonTitle = secondButtonTitle, let secondButtonStyle = secondButtonStyle {
      alert.addAction(
        UIAlertAction(
          title: secondButtonTitle, style: secondButtonStyle, handler: secondButtonHandler))
    }

    alert.popoverPresentationController?.sourceView = self.view

    alert.popoverPresentationController?.sourceRect = CGRect(
      origin: CGPoint(x: self.view.center.x, y: self.view.frame.height), size: .zero)
    present(alert, animated: true, completion: completion)

  }
}
