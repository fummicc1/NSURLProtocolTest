//
//  UIViewController+HandleAlertMessage.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/07.
//

import Foundation
import UIKit

extension UIViewController {
  func handleAlertMessage(_ message: AlertMessage, feedback: UINotificationFeedbackGenerator) {
    defer { feedback.prepare() }
    switch message.type {
    case .success:
      feedback.notificationOccurred(.success)
    case .error:
      feedback.notificationOccurred(.error)
    }
    if message.isOnlyFeedBack {
      return
    }
    self.showSimpleAlert(
      title: message.title, message: message.message, buttonTitle: message.buttonTitle)
  }

}
