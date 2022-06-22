//
//  ToiletMapView.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/08/05.
//

import Foundation
import MapKit
import RxRelay
import RxSwift
import UIKit

protocol ToiletMapViewDelegate: AnyObject {
  func didTapMapView(_ mapView: ToiletMapView)
}

class ToiletMapView: XibView {

  var didSelectToiletAnnotation: Observable<MKAnnotationView> {
    mapView
      .rx
      .didSelectAnnotationView
      .asObservable()
      .filter({ $0.annotation is MapAnnotation })
  }

  var didSelectHomeToiletAnnotation: Observable<MKAnnotationView> {
    mapView
      .rx
      .didSelectAnnotationView
      .asObservable()
      .filter({ $0.annotation is HomeToiletAnnotation })
  }

  var region: Observable<MKCoordinateRegion> {
    mapView.rx.region
  }

  var annotations: Binder<[MKAnnotation]> {
    mapView.rx.annotations
  }

  var annotationsData: [MKAnnotation] {
    mapView.annotations
  }

  var overlays: Binder<[MKOverlay]> {
    mapView.rx.overlays
  }

  var overlaysData: [MKOverlay] {
    mapView.overlays
  }

  var camera: Binder<MKMapCamera> {
    mapView.rx.camera
  }

  var nearestAnnotation: MKAnnotation? {
    didSet {
      guard let focus = nearestAnnotation else {
        return
      }
      mapView.setRegion(
        MKCoordinateRegion(
          center: focus.coordinate,
          latitudinalMeters: 500,
          longitudinalMeters: 500
        ),
        animated: false
      )
      if !mapView.annotations.contains(where: { $0.coordinate == focus.coordinate }) {
        mapView.addAnnotation(focus)
      }
      mapView.selectAnnotation(focus, animated: false)
    }
  }

  @IBOutlet private(set) var mapView: MKMapView!

  private let disposeBag: DisposeBag = DisposeBag()

  weak var delegate: ToiletMapViewDelegate?

  override func commonInit() {
    super.commonInit()
    mapView.translatesAutoresizingMaskIntoConstraints = false
    mapView.showsUserLocation = true
    mapView.userTrackingMode = .followWithHeading
    mapView.showsBuildings = false
    mapView.showsCompass = false

    let tap = UITapGestureRecognizer(target: self, action: #selector(didTapMapView))
    mapView.addGestureRecognizer(tap)
    mapView.delegate = self
  }

  @objc
  private func didTapMapView() {
    delegate?.didTapMapView(self)
  }

  func add(overlay: MKOverlay) {
    mapView.addOverlay(overlay)
  }

  func add(annotation: MKAnnotation) {
    mapView.addAnnotation(annotation)
  }

  func replaceAnnotations(with annotations: [MKAnnotation]) {
    mapView.rx.annotations.onNext(annotations)
  }

  func replaceOverlays(with overlays: [MKOverlay]) {
    mapView.rx.overlays.onNext(overlays)
  }

  func remove(overlays: [MKOverlay]) {
    mapView.removeOverlays(overlays)
  }

  func remove(annotations: [MKAnnotation]) {
    mapView.removeAnnotations(annotations)
  }

  func show(annotations: [MKAnnotation]) {
    mapView.showAnnotations(annotations, animated: false)
  }

  func deselect(annotation: MKAnnotation) {
    mapView.deselectAnnotation(annotation, animated: false)
  }

  func select(target: MKAnnotation) {
    mapView.selectAnnotation(target, animated: false)
  }

  func set(region: MKCoordinateRegion) {
    mapView.setRegion(region, animated: false)
  }

  func getFocusingCamenra(of annotation: MKAnnotation) -> MKMapCamera {
    MKMapCamera(
      lookingAtCenter: annotation.coordinate,
      fromDistance: 1000,
      pitch: 80,
      heading: 0
    )
  }

  func getDefaultRegion(of location: CLLocationCoordinate2D) -> MKCoordinateRegion {
    MKCoordinateRegion(
      center: location,
      latitudinalMeters: 1000,
      longitudinalMeters: 1000
    )
  }
}

extension ToiletMapView: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

    var view: MKMarkerAnnotationView? = nil

    // ToiletMapAnnotationより上に持ってくる
    if let annotation = annotation as? HomeToiletAnnotation {
      view = ToiletMapAnnotationView(
        annotation: annotation, reuseIdentifier: HomeToiletAnnotation.className)
      view?.markerTintColor = AppColor.mainColor
      view?.glyphImage = UIImage(systemSymbol: .houseFill)

    } else if let annotation = annotation as? ToiletMapAnnotation {

      view = ToiletMapAnnotationView(
        annotation: annotation, reuseIdentifier: ToiletMapAnnotation.className)
      view?.glyphImage =
        UIImage(named: "icon_ToiletCritic_pdf") ?? UIImage(named: "icon_ToiletCritic")
      view?.markerTintColor = AppColor.mainColor

    } else if let annotation = annotation as? iOSMapAnnotation {

      view = ToiletMapAnnotationView(
        annotation: annotation, reuseIdentifier: iOSMapAnnotation.className)
      view?.markerTintColor = AppColor.mainColor
      view?.glyphImage = UIImage(systemSymbol: .map)

    } else if let annotation = annotation as? ToiletRouteStepAnnotation {

      view = ToiletRouteStepAnnotationView(
        annotation: annotation, reuseIdentifier: ToiletRouteStepAnnotation.className)
      view?.glyphText = "\(Int(annotation.distance))M"
      view?.markerTintColor = AppColor.mainColor

    } else if let annotation = annotation as? MKUserLocation {
      let locationView = MKUserLocationView(
        annotation: annotation, reuseIdentifier: MKUserLocation.className)
      locationView.tintColor = AppColor.textColor
      return locationView
    }

    if let annotation = annotation as? MapAnnotation {
      if annotation.isHighlight {
        view?.glyphImage = UIImage(systemSymbol: .magnifyingglass)
      }
    }

    // ラスタライズを設定して、描画処理をキャッシュする
    view?.layer.shouldRasterize = true
    view?.layer.rasterizationScale = UIScreen.main.scale

    return view
  }

  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

    if let multiPolyline = overlay as? ToiletPolylineStepMultiPolyline {
      let renderer = ToiletPolylineStepMultiRenderer(multiPolyline: multiPolyline)
      renderer.strokeColor = AppColor.mainColor
      renderer.lineWidth = 4.0
      // ラスタライズを設定して、描画処理をキャッシュする
      renderer.shouldRasterize = true
      return renderer
    }

    if let polyline = overlay as? ToiletPolylineStepPolyline {
      let renderer = ToiletPolylineStepRenderer(polyline: polyline)
      renderer.fillColor = AppColor.mainColor
      renderer.strokeColor = AppColor.mainColor
      renderer.lineWidth = 4.0
      // ラスタライズを設定して、描画処理をキャッシュする
      renderer.shouldRasterize = true
      return renderer
    }
    return MKOverlayRenderer()
  }
}
