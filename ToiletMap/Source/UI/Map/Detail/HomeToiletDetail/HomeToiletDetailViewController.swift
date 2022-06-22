//
//  HomeToiletDetailViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/05/26.
//

import Foundation
import MapKit
import RxMKMapView
import RxSwift
import UIKit

class HomeToiletDetailViewController: BaseViewController {

  let viewModel: HomeToiletDetailViewModelOutput

  @IBOutlet private weak var baseView: UIView!
  @IBOutlet private weak var stackView: UIStackView!
  @IBOutlet private weak var dismissButton: UIButton!
  @IBOutlet private weak var titleLabel: UILabel!
  @IBOutlet private weak var showDirectionsButton: UIButton!
  @IBOutlet private weak var createToiletDiaryButton: UIButton!

  private var annotation: MapAnnotation

  init?(annotation: HomeToiletAnnotation) {
    self.annotation = annotation
    guard let viewModel = HomeToiletDetailViewModel(annotation: annotation) else {
      return nil
    }
    self.viewModel = viewModel
    super.init(nibName: Self.className, bundle: nil)
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

    baseView.layer.masksToBounds = true
    baseView.layer.cornerRadius = 32
    view.layer.masksToBounds = false
    view.layer.cornerRadius = 32
    view.layer.shadowColor = AppColor.shadowColor.cgColor
    view.layer.shadowOffset = CGSize(width: 4, height: 4)
    view.layer.shadowRadius = 32
    view.layer.shadowOpacity = 0.4
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.translatesAutoresizingMaskIntoConstraints = false
    configure(annotation: annotation)

    dismissButton.backgroundColor = AppColor.mainColor
    showDirectionsButton.tintColor = AppColor.mainColor
    showDirectionsButton.layer.borderColor = AppColor.mainColor.cgColor
    showDirectionsButton.setTitleColor(AppColor.mainColor, for: .normal)
    createToiletDiaryButton.tintColor = AppColor.mainColor
    createToiletDiaryButton.layer.borderColor = AppColor.mainColor.cgColor
    createToiletDiaryButton.setTitleColor(AppColor.mainColor, for: .normal)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    baseView.frame = view.bounds
  }

  func configure(annotation: MapAnnotation) {

    self.annotation = annotation

    // MARK: SETUP UI.
    titleLabel.text = annotation.title ?? annotation.toilet.name

    let dismissButtonTapped = dismissButton.rx.tap.asObservable()
    let requestRouteButtonTapped = showDirectionsButton
      .rx.tap
      .asObservable()

    dismissButtonTapped
      .subscribe(onNext: { [weak self] in
        self?.viewModel.didTapDismissButton()
      })
      .disposed(by: disposeBag)

    requestRouteButtonTapped
      .subscribe(onNext: { [weak self] in
        self?.viewModel.didTapRequestRouteButton()
      })
      .disposed(by: disposeBag)

    self.titleLabel.text = annotation.title?.flatMap({ $0 })

    let didTapCreateToiletDiaryButton = createToiletDiaryButton.rx.tap

    didTapCreateToiletDiaryButton
      .subscribe(onNext: { [weak self] in

        guard let self = self else {
          return
        }

        let toilet = self.annotation.toilet

        let vc = CreateToiletDiaryViewController.build(
          location: CLLocationCoordinate2D(
            latitude: toilet.latitude,
            longitude: toilet.longitude
          )
        )

        let nv = NavigationController(rootViewController: vc)

        nv.modalPresentationStyle = .fullScreen

        self.present(nv, animated: true, completion: nil)
      })
      .disposed(by: disposeBag)

    viewModel.closeDetailView
      .subscribe(onNext: { [weak self] _ in
        self?.removeToiletDetailView()
      }).disposed(by: disposeBag)

    viewModel.errorMessage
      .subscribe(onNext: { [weak self] errorMessage in
        self?.showErrorMessage(errorMessage)
      })
      .disposed(by: disposeBag)
  }

  private func removeToiletDetailView() {
    willMove(toParent: nil)
    view.removeFromSuperview()
    removeFromParent()
  }
}
