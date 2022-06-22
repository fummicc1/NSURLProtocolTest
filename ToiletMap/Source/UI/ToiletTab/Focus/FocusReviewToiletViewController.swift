//
//  FocusReviewToiletViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/07/13.
//

import Floaty
import Foundation
import MapKit
import RxCocoa
import RxSwift
import UIKit

class FocusReviewToiletViewController: BaseViewController {

  private weak var editReviewView: EditReviewView?

  private let mapView: ToiletMapView = {
    ToiletMapView(frame: .zero)
  }()

  private let fab: Floaty = {
    let fab = Floaty()
    fab.buttonColor = AppColor.mainColor
    fab.plusColor = AppColor.backgroundColor
    return fab
  }()

  private lazy var routeButton: FloatyItem = {
    let item = ShadowFloatyItem()
    item.handler = { [weak self] item in
      self?.viewModel.didTapRouteButton()
    }
    item.title = "経路"
    item.icon = UIImage(systemSymbol: .location)
    return item
  }()

  private lazy var createToiletDiaryButton: FloatyItem = {
    let item = ShadowFloatyItem()
    item.title = "日記作成"
    item.icon = UIImage(systemSymbol: .note)
    item.handler = { [weak self] item in

      guard let self = self, let toilet = self.review.toilet else {
        return
      }

      let vc = CreateToiletDiaryViewController.build(
        location: CLLocationCoordinate2D(
          latitude: toilet.latitude,
          longitude: toilet.longitude
        )
      )

      let nv = NavigationController(rootViewController: vc)

      nv.modalPresentationStyle = .fullScreen

      self.present(nv, animated: true, completion: nil)
    }
    return item
  }()

  private lazy var editReviewButton: FloatyItem = {
    let item = ShadowFloatyItem()
    item.handler = { [weak self] item in
      guard let self = self else {
        return
      }
      self.editReviewView?.isHidden = false
      self.showBlur(position: self.view.subviews.count - 1, on: self.view)
    }
    item.title = "レビューの編集"
    item.icon = UIImage(systemSymbol: .squareAndPencil)
    return item
  }()

  let viewModel: FocusReviewToiletViewModelType
  let review: ReviewPresentable

  init(review: ReviewPresentable, toilet: ToiletPresentable) {
    viewModel = FocusReviewToiletViewModel(toilet: toilet, review: review)
    self.review = review
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    mapView.delegate = self

    view.addSubview(mapView)

    mapView.snp.makeConstraints { maker in
      maker.top.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
    }

    buildEditReviewView()

    viewModel.errorMessage.subscribe(onNext: { [weak self] message in
      self?.showErrorMessage(message)
    })
    .disposed(by: disposeBag)

    viewModel.toiletMapAnnotation.subscribe(onNext: { [weak self] annotation in
      self?.mapView.replaceAnnotations(with: [annotation])

      let regionCenter = CLLocationCoordinate2D(
        latitude: annotation.toilet.latitude,
        longitude: annotation.coordinate.longitude
      )
      let region = MKCoordinateRegion(
        center: regionCenter,
        latitudinalMeters: 200,
        longitudinalMeters: 200
      )
      self?.mapView.set(region: region)

      self?.navigationItem.title = annotation.toilet.name
    })
    .disposed(by: disposeBag)

    viewModel
      .steps
      .observe(on: MainScheduler.instance)
      .subscribe({ [weak self] (event) in
        guard let self = self, let steps = event.element else { return }

        if steps.isEmpty { return }

        let _stepsOverlay = self.mapView.overlaysData.filter({
          $0 is ToiletPolylineStepMultiPolyline
        })

        self.mapView.remove(overlays: _stepsOverlay)

        let _annotations = self.mapView.annotationsData.filter({ $0 is ToiletRouteStepAnnotation })

        self.mapView.remove(annotations: _annotations)

        var polylines: [MKPolyline] = []

        for (index, step) in steps.enumerated() {
          let center = step.polyline.coordinate
          let clRegion = CLCircularRegion(center: center, radius: 15, identifier: "\(index)")

          let annotation = ToiletRouteStepAnnotation(
            coordinate: center, distance: step.distance, stepIndex: index)
          polylines.append(step.polyline)
          LocationShared.default.locationManager.startMonitoring(for: clRegion)
          self.mapView.add(annotation: annotation)
        }

        let multiPolyline = ToiletPolylineStepMultiPolyline(polylines)
        self.mapView.add(overlay: multiPolyline)

        let region = MKCoordinateRegion(
          center: steps[1].polyline.coordinate,
          latitudinalMeters: steps[1].distance + 100,
          longitudinalMeters: steps[1].distance + 100
        )

        self.mapView.set(region: region)
      })
      .disposed(by: disposeBag)

    viewModel
      .currentStep
      .observe(on: MainScheduler.instance)
      .withLatestFrom(viewModel.steps) { currentStep, steps in
        (currentStep, steps)
      }
      .subscribe(onNext: { [weak self] (currentStep, steps) in
        guard let self = self else {
          return
        }
        let (index, _) = currentStep

        if steps.isEmpty {
          return
        }
        // 最後のStepかどうかのFlag.
        let isLast = index == steps.count - 1
        let isFirst = index == 0

        if isLast {
          let feedback = UIImpactFeedbackGenerator(style: .light)
          feedback.impactOccurred()
          self.showNormalMessage("目的のトイレは近くです。")
        } else if isFirst {
          return
        }
        let annotation = self.mapView.annotationsData
          .compactMap({ $0 as? ToiletRouteStepAnnotation })
          .first(where: { $0.stepIndex == index - 1 })
        if let _annotation = annotation,
          let region = LocationShared.default.locationManager.monitoredRegions.first(where: {
            $0.identifier == "\(index - 1)"
          })
        {
          LocationShared.default.locationManager.stopMonitoring(for: region)
          self.mapView.remove(annotations: [_annotation])
        }
      })
      .disposed(by: disposeBag)

    viewModel.closeEditReviewView.subscribe(onNext: { [weak self] in
      guard let editView = self?.editReviewView else {
        return
      }
      self?.animateHidingEditReviewView(editView: editView)
    })
    .disposed(by: disposeBag)

    fab.addItem(item: routeButton)
    fab.addItem(item: editReviewButton)
    fab.addItem(item: createToiletDiaryButton)

    view.addSubview(fab)

    fab.snp.makeConstraints { maker in
      maker.height.width.equalTo(56)
      maker.bottom.trailing.equalTo(mapView).offset(-24)
    }
  }

  private func buildEditReviewView() {
    let editReviewView = EditReviewView(review: viewModel.review) { [weak self] newReview in
      self?.viewModel.commitReviewChange(review: newReview)
    }
    editReviewView.translatesAutoresizingMaskIntoConstraints = false
    editReviewView.isHidden = true
    self.editReviewView = editReviewView
    view.addSubview(editReviewView)
    editReviewView.snp.makeConstraints { maker in
      maker.center.equalToSuperview()
    }
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    if let editView = editReviewView, let touch = touches.first {
      let position = touch.location(in: view)
      if editView.frame.contains(position) {
        return
      }
      animateHidingEditReviewView(editView: editView)
    }
  }

  private func animateHidingEditReviewView(editView: EditReviewView) {
    UIView.transition(with: editView, duration: 0.3, options: [.curveEaseOut]) {
      editView.alpha = 0
    } completion: { [weak self] _ in
      editView.removeFromSuperview()
      self?.hideBlur()
      self?.buildEditReviewView()
    }
  }
}

extension FocusReviewToiletViewController: ToiletMapViewDelegate {
  func didTapMapView(_ mapView: ToiletMapView) {
  }
}
