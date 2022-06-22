//
//  BaseViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/07.
//

import Foundation
import RxCocoa
import RxSwift
import UIKit

class BaseViewController: UIViewController {
  let disposeBag = DisposeBag()
  let feedback = UINotificationFeedbackGenerator()
  private var blurEffect: UIBlurEffect = .init(style: .regular)
  private weak var blurView: UIVisualEffectView?
  private weak var messageView: MessageView?
  private weak var errorView: MessageView?

  func showBlur(position: Int = 0, on _view: UIView? = nil) {
    let view: UIView = _view ?? self.view
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.frame = view.bounds
    self.blurView = blurView

    if position == 0 {
      view.addSubview(blurView)
    } else {
      view.insertSubview(blurView, at: position)
    }
  }

  func hideBlur() {
    blurView?.removeFromSuperview()
  }

  func showNormalMessage(_ message: String, autoHide: Bool = false) {
    let messageView: MessageView
    self.errorView?.hide()
    if let _messageView = self.messageView {
      messageView = _messageView
    } else {
      messageView = MessageView(
        frame: .zero,
        text: message,
        textColor: nil
      )
      view.addSubview(messageView)
      messageView.snp.makeConstraints { make in
        make.top.equalTo(self.view.safeAreaLayoutGuide).offset(24)
        make.leading.equalTo(self.view).offset(16)
        make.trailing.equalTo(self.view).offset(-16)
        make.height.equalTo(0)
      }
      self.messageView = messageView
    }
    messageView.text = message

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      guard let self = self else {
        return
      }
      UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) { [weak self] in
        guard let self = self else {
          return
        }
        messageView.snp.updateConstraints { make in
          make.height.equalTo(64)
        }
        self.view.layoutIfNeeded()
      } completion: { _ in
        if autoHide {
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            messageView.hide()
          }
        }
      }

    }
  }

  func showErrorMessage(_ message: String, autoHide: Bool = true) {
    let errorView: MessageView
    self.messageView?.hide()
    if let _errorView = self.errorView {
      errorView = _errorView
    } else {
      errorView = MessageView(
        frame: .zero,
        text: message,
        textColor: AppColor.errorColor
      )
      view.addSubview(errorView)
      errorView.snp.makeConstraints { make in
        make.top.equalTo(self.view.safeAreaLayoutGuide).offset(24)
        make.leading.equalTo(self.view).offset(16)
        make.trailing.equalTo(self.view).offset(-16)
        make.height.equalTo(0)
      }
      self.errorView = errorView
    }
    errorView.text = message

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      guard let self = self else {
        return
      }
      UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) { [weak self] in
        guard let self = self else {
          return
        }
        errorView.snp.updateConstraints { make in
          make.height.equalTo(64)
        }
        self.view.layoutIfNeeded()
      } completion: { _ in
        if autoHide {
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            errorView.hide()
          }
        }
      }

    }
  }
}
