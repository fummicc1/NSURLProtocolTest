//
//  HomeViewController.swift
//  ToiletMap
//

//  Created by Fumiya Tanaka on 2020/03/27.
//

import Aiolos
import MapKit
import RxSwift
import SnapKit
import UIKit

struct TutorialModel {
  var state: TutorialState
  var targetAnnotation: MapAnnotation?
}

enum TutorialState: String {
  case start
  case tapAnnotation
  case tapArchive
  case tapArchiveList
  case tapArchiveListCell
  case tapRoute
  case done

  mutating func next() {
    switch self {
    case .start:
      self = .tapAnnotation
    case .tapAnnotation:
      self = .tapArchive
    case .tapArchive:
      self = .tapArchiveList
    case .tapArchiveList:
      self = .tapArchiveListCell
    case .tapArchiveListCell:
      self = .tapRoute
    case .tapRoute:
      self = .done
    case .done:
      UserDefaults.standard.setValue(TutorialState.done.rawValue, forKey: "tutorial_state")
    }
  }

  var isDone: Bool {
    if case TutorialState.done = self {
      return true
    } else {
      return false
    }
  }

  var isIdle: Bool {
    self == .done || self == .start
  }
}

enum CoachmarkPosition {
  case top
  case center
  case bottom
}

protocol HomeViewControllerDelegate: AnyObject {
  func show(panel: Panel, completion: (() -> Void)?)
}

class HomeViewController: BaseViewController {

  private weak var archiveListViewController: ArchiveListViewController?

  weak var toiletMapViewController: ToiletMapViewController?
  var showTutorial: Bool = false

  init(showTutorial: Bool = false) {
    self.showTutorial = showTutorial
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let toiletMapViewController = ToiletMapViewController()
    addChild(toiletMapViewController)
    view.addSubview(toiletMapViewController.view)
    toiletMapViewController.didMove(toParent: self)
    toiletMapViewController.homeDelegate = self

    toiletMapViewController.view.snp.makeConstraints { maker in
      maker.top.trailing.bottom.leading.equalToSuperview()
    }

    self.toiletMapViewController = toiletMapViewController
  }
}

extension HomeViewController: HomeViewControllerDelegate {
  func show(panel: Panel, completion: (() -> Void)?) {
    panel.add(to: self, completion: completion)
  }
}
