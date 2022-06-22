//
//  ToiletDetailViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/07.
//

import Aiolos
import Combine
import Foundation
import MapKit
import RxMKMapView
import RxSwift
import SwiftUI
import UIKit

class ToiletDetailViewController: BaseViewController {

  let viewModel: ToiletDetailViewModelOutput

  @IBOutlet weak var baseView: UIView!
  @IBOutlet weak var stackView: UIStackView!
  @IBOutlet weak var dismissButton: UIButton!
  @IBOutlet weak var reviewButton: UIButton!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subTitleView: UILabel!

  @IBOutlet weak var showDirectionsButton: UIButton!
  @IBOutlet weak var archiveButton: UIButton!
  @IBOutlet weak var reviewStackView: UIStackView!
  @IBOutlet weak var actionStackView: UIStackView!

  weak var reviewContentView: UIView?

  @IBOutlet weak var topActionStackView: UIStackView!

  @IBOutlet weak var writeDiaryButton: RadiusButton!

  weak var reviewGraphHostingController: UIHostingController<ReviewGraphicalView>?

  private var annotation: MapAnnotation
  private let onDismiss: () -> Void

  init?(annotation: MapAnnotation, onDismiss: @escaping () -> Void) {
    self.annotation = annotation
    self.onDismiss = onDismiss
    guard let viewModel = ToiletDetailViewModel(annotation: annotation) else {
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
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.translatesAutoresizingMaskIntoConstraints = false
    configure(annotation: annotation)

    dismissButton.backgroundColor = AppColor.mainColor
    archiveButton.tintColor = AppColor.mainColor
    archiveButton.layer.borderColor = AppColor.mainColor.cgColor
    archiveButton.setTitleColor(AppColor.mainColor, for: .normal)
    showDirectionsButton.tintColor = AppColor.mainColor
    showDirectionsButton.layer.borderColor = AppColor.mainColor.cgColor
    showDirectionsButton.setTitleColor(AppColor.mainColor, for: .normal)
    reviewButton.tintColor = AppColor.mainColor
    reviewButton.layer.borderColor = AppColor.mainColor.cgColor
    reviewButton.setTitleColor(AppColor.mainColor, for: .normal)
    writeDiaryButton.tintColor = AppColor.mainColor
    writeDiaryButton.layer.borderColor = AppColor.mainColor.cgColor
    writeDiaryButton.setTitleColor(AppColor.mainColor, for: .normal)

    configureGraphicalView()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    baseView.frame = view.bounds
  }

  private func configureGraphicalView() {

    let reviewScore = viewModel.reviewScorePublisher

    let reviewGraphHostingController =
      buildReviewGraphicalView(
        value: reviewScore
      )
    self.reviewGraphHostingController = reviewGraphHostingController
    self.reviewStackView.addArrangedSubview(reviewGraphHostingController.view)
  }

  func configure(annotation: MapAnnotation) {

    self.annotation = annotation

    // MARK: SETUP UI.

    if annotation is HomeToiletAnnotation {
      // レビューなどができないようにする
      reviewButton.isHidden = true
      archiveButton.isHidden = true
    }

    titleLabel.text = annotation.title ?? annotation.toilet.name
    subTitleView.text = annotation.subtitle ?? annotation.toilet.detail

    let writeDiaryButtonTapped = writeDiaryButton.rx.tap.asObservable()

    let dismissButtonTapped = dismissButton.rx.tap.asObservable()
    let archiveButtonTapped = archiveButton.rx.tap.asObservable()
    let requestRouteButtonTapped = showDirectionsButton
      .rx.tap
      .asObservable()
    let reviewButtonTapped = reviewButton
      .rx.tap
      .asObservable()

    dismissButtonTapped
      .subscribe(onNext: { [weak self] in
        self?.viewModel.didTapDismissButton()
      })
      .disposed(by: disposeBag)

    archiveButtonTapped
      .subscribe(onNext: { [weak self] in
        self?.viewModel.didTapArchiveButton()
      })
      .disposed(by: disposeBag)

    requestRouteButtonTapped
      .subscribe(onNext: { [weak self] in
        self?.viewModel.didTapRequestRouteButton()
        self?.onDismiss()
      })
      .disposed(by: disposeBag)

    reviewButtonTapped
      .subscribe(onNext: { [weak self] in
        self?.viewModel.didTapReviewButton()
      })
      .disposed(by: disposeBag)

    writeDiaryButtonTapped
      .subscribe(onNext: { [weak self] in
        guard let self = self else {
          assertionFailure()
          return
        }

        let toilet = self.annotation.toilet

        let createToiletDiaryViewController = CreateToiletDiaryViewController.build(
          location: CLLocationCoordinate2D(
            latitude: toilet.latitude,
            longitude: toilet.longitude
          )
        )

        let navigationController = NavigationController(
          rootViewController: createToiletDiaryViewController)

        navigationController.modalPresentationStyle = .fullScreen

        self.onDismiss()
        self.presentingViewController?.present(
          navigationController,
          animated: true,
          completion: nil
        )
      })
      .disposed(by: disposeBag)

    self.titleLabel.text = annotation.title?.flatMap({ $0 })
    self.subTitleView.text = annotation.subtitle?.flatMap({ $0 })

    viewModel.isReviewed
      .subscribe(onNext: { [weak self] isReviewed in
        self?.reviewButton.isEnabled = isReviewed.reverse()
        self?.reviewButton.setTitle(isReviewed ? "レビュー済み" : "レビューする", for: .normal)
      })
      .disposed(by: disposeBag)

    viewModel.closeDetailView
      .subscribe(onNext: { [weak self] _ in
        self?.removeToiletDetailView()
      }).disposed(by: disposeBag)

    viewModel.shouldPresentReviewViewController.subscribe { [weak self] event in
      guard let self = self, let annotation = event.element else {
        return
      }

      let reviewViewController = ReviewViewController(storedMapAnnotation: annotation)
      let navigationController = NavigationController(rootViewController: reviewViewController)

      self.onDismiss()
      self.presentingViewController?.present(
        navigationController,
        animated: true,
        completion: nil
      )
    }.disposed(by: disposeBag)

    viewModel
      .isArchiving
      .flatMap(Observable.from(optional:))
      .subscribe(onNext: { [weak self] isArchiving in
        if isArchiving {
          self?.archiveButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
          self?.archiveButton.setTitle("保存を解除", for: .normal)
        } else {
          self?.archiveButton.setImage(UIImage(systemName: "heart"), for: .normal)
          self?.archiveButton.setTitle("保存", for: .normal)
        }
      })
      .disposed(by: disposeBag)

    viewModel.errorMessage
      .subscribe(onNext: { [weak self] errorMessage in
        self?.showErrorMessage(errorMessage)
      })
      .disposed(by: disposeBag)
  }

  private func removeToiletDetailView() {
    onDismiss()
  }
}
