//
//  CreateHomeToiletViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/05/26.
//

import Foundation
import MapKit
import UIKit

class CreateHomeToiletViewController: BaseViewController {

  @IBOutlet private weak var mapView: MKMapView!

  let viewModel: CreateHomeToiletViewModelType

  init(viewModel: CreateHomeToiletViewModelType = CreateHomeToiletViewModel()) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.title = "自宅トイレの設定"

    let rightBarButtonItem = BarButtonItem(systemItem: .save)
    let leftBarButtonItem = BarButtonItem(systemItem: .close)

    navigationItem.rightBarButtonItem = rightBarButtonItem

    navigationItem.rightBarButtonItem?.rx.tap.subscribe(onNext: { [weak self] in
      self?.viewModel.determine()
    })
    .disposed(by: disposeBag)

    navigationItem.leftBarButtonItem = leftBarButtonItem

    navigationItem.leftBarButtonItem?.rx.tap.subscribe(onNext: { [weak self] in
      self?.dismiss(animated: true, completion: nil)
    })
    .disposed(by: disposeBag)

    mapView.showsUserLocation = true
    mapView.delegate = self
    if let coordinate = LocationShared.default.locationManager.location?.coordinate {
      mapView.setRegion(
        MKCoordinateRegion(center: coordinate, latitudinalMeters: 100, longitudinalMeters: 100),
        animated: true)
    }

    // MARK: ViewModel
    viewModel.error.subscribe(onNext: { [weak self] _ in
      self?.showErrorMessage("エラーが発生しました")
    })
    .disposed(by: disposeBag)

    viewModel.location.subscribe(onNext: { [weak self] location in
      guard let self = self else {
        return
      }
      let distance: Double?
      if let currentPlace = LocationShared.default.locationManager.location?.coordinate {
        distance = location.calculateDistance(with: currentPlace)
      } else {
        distance = nil
      }
      let fragment = HomeToiletFragment(latitude: location.latitude, longitude: location.longitude)

      let annotation = HomeToiletAnnotation(toilet: fragment, distance: distance)
      self.mapView.removeAnnotations(self.mapView.annotations)
      self.mapView.addAnnotation(annotation)
    }).disposed(by: disposeBag)

    viewModel.oldHomeToilet.subscribe(onNext: { [weak self] presentable in
      guard let self = self else {
        return
      }
      let annotation = HomeToiletAnnotation(toilet: presentable, distance: nil)
      self.mapView.removeAnnotations(self.mapView.annotations)
      self.mapView.addAnnotation(annotation)
    })
    .disposed(by: disposeBag)

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapMapView(_:)))
    mapView.addGestureRecognizer(tapGesture)

    viewModel.completeUpdating.subscribe(onNext: { [weak self] in
      self?.dismiss(animated: true, completion: nil)
    })
    .disposed(by: disposeBag)
  }

  @objc
  private func didTapMapView(_ sender: UITapGestureRecognizer) {
    let location = sender.location(in: sender.view)
    let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
    viewModel.changeLocation(coordinate)
  }
}

extension CreateHomeToiletViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if let annotation = annotation as? HomeToiletAnnotation {
      let view = MKMarkerAnnotationView(
        annotation: annotation, reuseIdentifier: HomeToiletAnnotation.className)
      view.markerTintColor = AppColor.mainColor
      view.glyphImage = UIImage(systemSymbol: .houseFill)
      return view
    }
    return nil
  }
}
