//
//  FocusToiletViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/03/18.
//

import Floaty
import MapKit
import RxCocoa
import RxSwift
import UIKit

class FocusToiletViewController: BaseViewController {

  private let mapView: ToiletMapView = {
    ToiletMapView(frame: .zero)
  }()

  let viewModel: FocusToiletViewModelType
  let toilet: ToiletPresentable

  private let fab = Floaty()

  private lazy var routeButton: FloatyItem = {
    let item = ShadowFloatyItem()
    item.title = "経路"
    item.icon = UIImage(systemSymbol: .location)
    item.handler = { [weak self] item in
      self?.viewModel.didTapRouteButton()
    }
    return item
  }()

  private lazy var createToiletDiaryButton: FloatyItem = {
    let item = ShadowFloatyItem()
    item.title = "日記作成"
    item.icon = UIImage(systemSymbol: .note)
    item.handler = { [weak self] item in

      guard let self = self else {
        return
      }

      let vc = CreateToiletDiaryViewController.build(
        location: CLLocationCoordinate2D(
          latitude: self.toilet.latitude,
          longitude: self.toilet.longitude
        )
      )

      let nv = NavigationController(rootViewController: vc)

      nv.modalPresentationStyle = .fullScreen

      self.present(nv, animated: true, completion: nil)
    }
    return item
  }()

  init(toilet: ToiletPresentable) {
    self.toilet = toilet
    viewModel = FocusToiletViewModel(toilet: toilet)
    super.init(nibName: Self.className, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationController?.setNavigationBarHidden(false, animated: false)

    mapView.delegate = self

    view.addSubview(mapView)

    mapView.snp.makeConstraints { maker in
      maker.top.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
    }

    fab.buttonColor = AppColor.mainColor
    fab.plusColor = AppColor.backgroundColor
    fab.addItem(item: routeButton)
    fab.addItem(item: createToiletDiaryButton)
    fab.sticky = true
    fab.fabDelegate = self
    view.addSubview(fab)

    fab.snp.makeConstraints { maker in
      maker.bottom.trailing.equalTo(mapView).offset(-24)
      maker.height.width.equalTo(56)
    }

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
  }
}

extension FocusToiletViewController: FloatyDelegate {

}

extension FocusToiletViewController: ToiletMapViewDelegate {
  func didTapMapView(_ mapView: ToiletMapView) {

  }
}
