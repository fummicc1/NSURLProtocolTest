//
//  AddToiletMapViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2019/10/26.
//

import CoreLocation
import FirebaseFirestore
import MapKit
import RxCocoa
import RxMKMapView
import RxSwift
import UIKit

class CreateToiletViewController: BaseViewController {

  @IBOutlet private weak var nameTextField: UITextField! {
    didSet {
      nameTextField.delegate = self
    }
  }

  @IBOutlet private weak var detailTextView: PlaceholderTextView!
  @IBOutlet private weak var detailTextViewBottomSeparator: UIView! {
    didSet {
      detailTextViewBottomSeparator.backgroundColor = AppColor.mainColor
    }
  }

  @IBOutlet private weak var locationSwitch: ColoredSwitch!
  @IBOutlet private weak var mapView: MKMapView! {
    didSet {
      mapView.delegate = self
    }
  }
  @IBOutlet private weak var borderView: UIView!

  private let viewModel: CreateToiletViewModelType = CreateToiletViewModel()

  init() {
    super.init(nibName: Self.className, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    guard
      let view =
        UINib(nibName: CreateToiletViewController.className, bundle: nil).instantiate(
          withOwner: self, options: nil
        ).first as? UIView
    else {
      return
    }
    self.view = view
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configure()
    configureNavigationBar()

    borderView.backgroundColor = AppColor.mainColor
    detailTextView.configure(placeholder: "説明")
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    view.endEditing(true)
  }

  private func configureNavigationBar() {
    let closeButton = BarButtonItem(
      barButtonSystemItem: .close, target: self, action: #selector(close))
    let createButton = BarButtonItem(
      barButtonSystemItem: .add, target: self, action: #selector(create))

    navigationItem.rightBarButtonItem = createButton
    navigationItem.leftBarButtonItem = closeButton

    navigationItem.title = "トイレを作成"
  }

  @objc
  func add() {
    create()
  }

  @objc
  func close() {
    dismiss(animated: true, completion: nil)
  }

  @objc
  private func create() {

    defer {
      feedback.prepare()
    }

    viewModel.create()
      .subscribe(onSuccess: { [weak self] _ in
        self?.showNormalMessage("正常に作成しました")
        self?.feedback.notificationOccurred(.success)
        self?.dismiss(animated: true, completion: nil)
      })
      .disposed(by: disposeBag)

    viewModel.errorMessage
      .subscribe(onNext: { [weak self] message in
        self?.feedback.notificationOccurred(.error)
        self?.showErrorMessage(message)
      })
      .disposed(by: disposeBag)
  }
}

extension CreateToiletViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}

extension CreateToiletViewController: MKMapViewDelegate {
  private func configure() {

    mapView.rx.didAddAnnotationViews.asObservable()
      .subscribe { [weak self] (event) in
        guard let self = self,
          let view = event.element?.first,
          let coordinate = view.annotation?.coordinate
        else { return }
        self.viewModel.changeLocation(coordinate: coordinate)
      }
      .disposed(by: disposeBag)

    nameTextField.rx.text.orEmpty
      .subscribe(onNext: { [weak self] name in
        self?.viewModel.update(name: name)
      })
      .disposed(by: disposeBag)

    detailTextView.rx.text.orEmpty
      .subscribe(onNext: { [weak self] detail in
        self?.viewModel.update(detail: detail)
      })
      .disposed(by: disposeBag)

    locationSwitch.rx.isOn
      .subscribe(onNext: { [weak self] isOn in
        self?.viewModel.updateIsOnSwitch(isOn: isOn)
      })
      .disposed(by: disposeBag)

    let tap = UITapGestureRecognizer(target: self, action: #selector(didTapMapView(_:)))
    mapView.addGestureRecognizer(tap)

    guard let region = viewModel.getMapRegion() else {
      return
    }

    mapView.setRegion(region, animated: false)
    mapView.showsUserLocation = true
  }

  @objc
  private func didTapMapView(_ sender: UITapGestureRecognizer) {
    let location = sender.location(in: sender.view)
    let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    mapView.removeAnnotations(mapView.annotations)
    mapView.addAnnotation(annotation)

    viewModel.changeLocation(coordinate: coordinate)
    viewModel.updateIsOnSwitch(isOn: false)
    locationSwitch.rx.isOn.onNext(false)
  }

  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

    if annotation is MKUserLocation { return nil }

    let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
    view.markerTintColor = AppColor.mainColor
    return view
  }
}
