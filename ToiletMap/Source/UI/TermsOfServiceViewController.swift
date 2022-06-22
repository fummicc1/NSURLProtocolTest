//
//  TermsOfServiceViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/05.
//

import RxSwift
import UIKit
import WebKit

class TermsOfServiceViewController: BaseViewController {

  @IBOutlet private weak var webView: WKWebView!

  private let canDismiss: Bool

  init(canDismiss: Bool = false) {
    self.canDismiss = canDismiss
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    guard
      let view =
        UINib(nibName: Self.className, bundle: nil).instantiate(withOwner: self, options: nil).first
        as? UIView
    else {
      fatalError()
    }
    self.view = view
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    webView.load(
      URLRequest(url: URL(string: "https://fummicc1.github.io/ToiletMap_Terms_And_Conditions/")!))

    let dismissButton = BarButtonItem(
      barButtonSystemItem: .close, target: self, action: #selector(close))

    if canDismiss {
      navigationItem.leftBarButtonItem = dismissButton
    }

    navigationItem.title = "Terms of services"
  }

  @objc
  private func close() {
    dismiss(animated: true, completion: nil)
  }
}
