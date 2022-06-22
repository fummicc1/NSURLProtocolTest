//
//  AlertMessage.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/02.
//

import Foundation
import UIKit

struct AlertMessage {
  let alertStyle: (UIAlertController.Style)?
  let title: String
  let message: String?
  let buttonTitle: String?
  let buttonStyle: (UIAlertAction.Style)?
  let handler: ((UIAlertAction) -> Void)?
  let secondButtonTitle: String?
  let secondButtonStyle: (UIAlertAction.Style)?
  let secondButtonHandler: ((UIAlertAction) -> Void)?
  let type: AlertType
  let isOnlyFeedBack: Bool

  init(
    alertStyle: (UIAlertController.Style) = .alert,
    title: String = "",
    message: String? = nil,
    buttonTitle: String? = nil,
    buttonStyle: (UIAlertAction.Style)? = nil,
    handler: ((UIAlertAction) -> Void)? = nil,
    secondButtonTitle: String? = nil,
    secondButtonStyle: (UIAlertAction.Style)? = nil,
    secondButtonHandler: ((UIAlertAction) -> Void)? = nil,
    type: AlertType,
    isOnlyFeedBack: Bool = false
  ) {
    self.alertStyle = alertStyle
    self.title = title
    self.message = message
    self.buttonTitle = buttonTitle
    self.buttonStyle = buttonStyle
    self.handler = handler
    self.secondButtonTitle = secondButtonTitle
    self.secondButtonStyle = secondButtonStyle
    self.secondButtonHandler = secondButtonHandler
    self.type = type
    self.isOnlyFeedBack = isOnlyFeedBack
  }

  enum AlertType {
    case success
    case error(Error)
  }
}
