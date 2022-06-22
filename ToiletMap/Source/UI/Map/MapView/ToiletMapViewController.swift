//
//  ToiletMapViewController.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2019/10/26.
//

import CoreLocation
import FirebaseFirestore
import MapKit
import NVActivityIndicatorView
import RxCocoa
import RxCoreLocation
import RxMKMapView
import RxSwift
import SFSafeSymbols
import SnapKit
import UIKit

class ToiletMapViewController: BaseViewController {

  let viewModel: ToiletMapViewModel = ToiletMapViewModelImpl()
  let searchViewModel: SearchViewModel = SearchViewModel()

  let imageConfiguration: UIImage.SymbolConfiguration = .init(
    font: UIFont.preferredFont(forTextStyle: .title3), scale: .medium)

  weak var searchIndicatorView: NVActivityIndicatorView?

  let mapView: ToiletMapView = {
    let mapView = ToiletMapView(frame: .zero)
    return mapView
  }()

  lazy var userTrackingBarButton: CustomUserTrackingButton = {
    let button = CustomUserTrackingButton(mapView: mapView.mapView)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = AppColor.backgroundColor
    button.tintColor = AppColor.mainColor
    button.layer.borderWidth = 1
    button.layer.borderColor = button.tintColor.cgColor
    button.layer.cornerRadius = 8
    button.layer.cornerCurve = .continuous
    return button
  }()

  lazy var homeToiletButton: RadiusButton = {
    let button = RadiusButton(
      frame: .zero,
      cornerRadius: 8,
      borderWidth: 1,
      buttonTitle: nil,
      buttonImage: UIImage(systemSymbol: .house, withConfiguration: imageConfiguration)
    )
    button.contentEdgeInsets = .init(top: 4, left: 8, bottom: 4, right: 8)
    button.backgroundColor = AppColor.backgroundColor
    button.tintColor = AppColor.mainColor
    button.rx.tap
      .withLatestFrom(viewModel.homeToiletAnnotation)
      .subscribe(onNext: { [weak self] homeToiletAnnotation in
        if let annotation = homeToiletAnnotation {
          self?.mapView.show(annotations: [annotation])
          // 自宅トイレをタップする手間を減らしたい
          DispatchQueue.main.async {
            self?.mapView.select(target: annotation)
          }
        } else {
          self?.showNormalMessage("設定画面から自宅トイレを設定してください")
        }
      })
      .disposed(by: disposeBag)
    button.rx.controlEvent(.touchDown).subscribe(onNext: {
      UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
        button.backgroundColor = AppColor.mainColor
        button.tintColor = AppColor.backgroundColor
      }
    })
    .disposed(by: disposeBag)

    button.rx.controlEvent([.touchUpInside, .touchCancel, .touchDragOutside]).subscribe(onNext: {
      UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
        button.backgroundColor = AppColor.backgroundColor
        button.tintColor = AppColor.mainColor
      }
    })
    .disposed(by: disposeBag)
    return button
  }()

  private lazy var stackView: UIStackView = {
    let stackView: UIStackView = .init(
      arrangedSubviews: [
        userTrackingBarButton,
        homeToiletButton,
      ]
    )
    stackView.axis = .vertical
    stackView.spacing = 16
    stackView.distribution = .fillEqually
    return stackView
  }()

  var homeToiletDetailViewController: HomeToiletDetailViewController? {
    didSet {
      self.injectHomeToiletDetailViewRelation()
    }
  }

  private var toiletDetailViewController: ToiletDetailViewController?

  var searchResultViewController: SearchToiletResultViewController!

  weak var homeDelegate: HomeViewControllerDelegate?

  init() {
    super.init(nibName: nil, bundle: nil)
    // TODO: Rename
    self.searchResultViewController = SearchToiletResultViewController(delegate: self)
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

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    view.endEditing(false)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Initialize LocationShared
    LocationShared.default.locationManager.requestWhenInUseAuthorization()

    let searchIndicatorView = NVActivityIndicatorView(
      frame: .zero,
      type: .ballScaleRippleMultiple,
      color: AppColor.mainColor
    )
    view.addSubview(searchIndicatorView)
    self.searchIndicatorView = searchIndicatorView

    // superview layout setup before adding subviews.
    self.configureMapView()

    self.view.addSubview(stackView)

    let rightBarButton = UIBarButtonItem(systemItem: .add)
    navigationItem.rightBarButtonItem = rightBarButton
    navigationItem.rightBarButtonItem?
      .rx.tap
      .subscribe(onNext: { [weak self] in
        let createViewController = CreateToiletViewController()
        let navigationController = NavigationController(
          rootViewController: createViewController
        )
        navigationController.isModalInPresentation = true
        self?.present(
          navigationController,
          animated: true,
          completion: nil
        )
      })
      .disposed(by: disposeBag)

    self.setupConstraints()
    setupForSearchResultController()
    self.configureViewModel()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(false, animated: false)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    searchIndicatorView?.frame = .init(origin: .zero, size: .init(width: 56, height: 56))
    searchIndicatorView?.center = view.window?.center ?? .zero
  }

  private func setupConstraints() {

    mapView.snp.makeConstraints { maker in
      maker.top.leading.trailing.bottom.equalToSuperview()
    }

    stackView.snp.makeConstraints { maker in
      maker.leading.equalTo(view.safeAreaLayoutGuide).inset(8)
      maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
    }
  }

  private func setToiletDetailViewConstraint(_ toiletDetailView: UIView, height: CGFloat = 320) {
    UIView.animate(withDuration: 0.3) {
      toiletDetailView.snp.makeConstraints { maker in
        maker.trailing.equalToSuperview().offset(-16)
        maker.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(-16)
        maker.leading.equalToSuperview().offset(16)
        maker.height.equalTo(height)
      }
      toiletDetailView.layoutIfNeeded()
    }
  }
}

extension ToiletMapViewController {

  private func configureViewModel() {
    LocationShared.default
      .locationManager
      .rx
      .didChangeAuthorization
      .asObservable()
      .observe(on: MainScheduler.instance)
      .share()
      .subscribe { [weak self] (event) in
        guard let self = self, let status = event.element?.status,
          let location = event.element?.manager.location
        else { return }

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:

          let region = self.mapView.getDefaultRegion(of: location.coordinate)

          self.mapView.set(region: region)
        default: break
        }
      }.disposed(by: disposeBag)

    viewModel.errorMessage
      .subscribe(onNext: { [weak self] errorMessage in
        self?.showErrorMessage(errorMessage)
      })
      .disposed(by: disposeBag)

    let toiletMapAnnotations: Observable<[MapAnnotation]> =
      Observable
      .combineLatest(viewModel.toiletMapAnnotations, viewModel.homeToiletAnnotation)
      .map({ annotations, home in
        var annotations = annotations
        if let home = home {
          annotations.append(home)
        }
        return annotations
      })

    toiletMapAnnotations
      .subscribe(onNext: { [weak self] annotations in
        guard let self = self else {
          return
        }
        if let old = self.mapView.mapView.annotations.first(where: {
          annotations.map(\.coordinate).contains($0.coordinate)
        }) {
          self.mapView.mapView.removeAnnotation(old)
        }
        self.mapView.mapView.addAnnotations(annotations)
      })
      .disposed(by: disposeBag)
  }

  private func injectHomeToiletDetailViewRelation() {
    homeToiletDetailViewController?.viewModel
      .routesDetected
      .observe(on: MainScheduler.instance)
      .subscribe({ [weak self] (event) in
        guard let self = self, let steps = event.element else { return }

        if steps.isEmpty { return }

        let _stepsOverlay = self.mapView.overlaysData
          .filter({ $0 is ToiletPolylineStepMultiPolyline })

        self.mapView.remove(overlays: _stepsOverlay)

        let _annotations = self.mapView.annotationsData
          .filter({ $0 is ToiletRouteStepAnnotation })

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

    homeToiletDetailViewController?.viewModel
      .currentStepUpdated
      .observe(on: MainScheduler.instance)
      .subscribe({ [weak self] (event) in
        guard let self = self,
          let (index, distance) = event.element,
          let steps = self.homeToiletDetailViewController?.viewModel.routeSteps
        else {
          return
        }
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
          annotation?.title = "\(distance) m"
          LocationShared.default.locationManager.stopMonitoring(for: region)
          self.mapView.remove(annotations: [_annotation])
        }
      })
      .disposed(by: disposeBag)

    homeToiletDetailViewController?.viewModel
      .closeDetailView
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] annotation in
        self?.mapView.deselect(annotation: annotation)
      })
      .disposed(by: disposeBag)
  }

  private func configureToiletDetailHalfModalViewController() {
    guard let toiletDetailViewModel = toiletDetailViewController?.viewModel else {
      return
    }
    toiletDetailViewModel
      .routesDetected
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

    toiletDetailViewModel
      .currentStepUpdated
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] currentStep in
        let steps = toiletDetailViewModel.routeSteps
        guard let self = self else {
          return
        }
        let (index, distance) = currentStep

        if steps.isEmpty {
          return
        }

        self.showNormalMessage("次のステップまで\(distance)メートル")
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

  private func configureMapView() {
    mapView.delegate = self
    view.addSubview(mapView)

    mapView.didSelectToiletAnnotation.filter({ !($0.annotation is HomeToiletAnnotation) }).subscribe
    { [weak self] (event) in
      guard let self = self,
        let annotationView = event.element,
        let annotation = annotationView.annotation as? MapAnnotation
      else {
        return
      }
      if let vc = self.toiletDetailViewController {
        vc.dismiss(animated: true)
      }
      guard
        let toiletDetailViewController = ToiletDetailViewController(
          annotation: annotation,
          onDismiss: {
            self.toiletDetailViewController?.dismiss(animated: true)
          })
      else {
        return
      }
      if let sheet = toiletDetailViewController.sheetPresentationController {
        sheet.detents = [.medium()]
      }
      self.present(toiletDetailViewController, animated: true)
      self.toiletDetailViewController = toiletDetailViewController
      self.configureToiletDetailHalfModalViewController()
    }
    .disposed(by: disposeBag)

    // MARK: For HomeToiletAnnotation
    mapView.didSelectToiletAnnotation.filter({ $0.annotation is HomeToiletAnnotation }).subscribe {
      [weak self] (event) in
      guard let self = self,
        let annotationView = event.element,
        let annotation = annotationView.annotation as? HomeToiletAnnotation
      else {
        return
      }

      if let homeToiletDetailViewController = self.homeToiletDetailViewController {

        homeToiletDetailViewController.willMove(toParent: nil)
        homeToiletDetailViewController.view.removeFromSuperview()
        homeToiletDetailViewController.removeFromParent()
      }
      guard
        let homeToiletDetailViewController = HomeToiletDetailViewController(annotation: annotation)
      else {
        return
      }
      self.addChild(homeToiletDetailViewController)
      self.view.addSubview(homeToiletDetailViewController.view)
      homeToiletDetailViewController.didMove(toParent: self)

      homeToiletDetailViewController.view.frame.origin.y = UIScreen.main.bounds.size.height

      self.setToiletDetailViewConstraint(homeToiletDetailViewController.view, height: 160)
      self.homeToiletDetailViewController = homeToiletDetailViewController

      let camera = MKMapCamera(
        lookingAtCenter: annotation.coordinate, fromDistance: 1000, pitch: 80, heading: 0)
      self.mapView.camera.onNext(camera)
    }
    .disposed(by: disposeBag)
  }
}

extension ToiletMapViewController: UIAdaptivePresentationControllerDelegate {
  func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController)
  {
    presentationController.presentedViewController.showSimpleAlert(
      alertStyle: .actionSheet,
      title: "レビューを破棄しますか？",
      message: "レビュー内容は復元できません。",
      buttonTitle: "破棄",
      buttonStyle: .destructive,
      handler: { (_) in
        self.dismiss(animated: true, completion: nil)
      }, secondButtonTitle: "キャンセル", secondButtonStyle: .cancel)
  }
}

extension ToiletMapViewController: ToiletMapViewDelegate {
  func didTapMapView(_ mapView: ToiletMapView) {
    toiletDetailViewController?.dismiss(animated: true)
    mapView.mapView.selectedAnnotations.forEach { annotation in
      mapView.deselect(annotation: annotation)
    }
  }
}

extension ToiletMapViewController: SearchToiletResultViewControllerDelegate {
  func searchViewController(
    _ searchViewController: SearchToiletResultViewController, didTapToilet toilet: ToiletPresentable
  ) {
    let annotation: MapAnnotation
    if let _annotation = viewModel.toiletMapAnnotationsValue.first(where: { annotation in
      let lat = annotation.toilet.latitude
      let long = annotation.toilet.longitude
      return toilet.latitude == lat && toilet.longitude == long
    }) {
      annotation = _annotation
    } else {
      annotation = ToiletMapAnnotation(toilet: toilet)
      mapView.add(annotation: annotation)
    }
    DispatchQueue.main.async {
      self.mapView.mapView.showAnnotations([annotation], animated: true)
      self.searchResultViewController.dismiss(animated: true)
    }
  }
}

extension ToiletMapViewController {

  override var navigationItem: UINavigationItem {
    if let parent = parent {
      return parent.navigationItem
    }
    return super.navigationItem
  }

  func setupForSearchResultController() {

    // MARK: SearchControllerの設定
    let searchController = UISearchController(
      searchResultsController: SearchToiletResultViewController(
        delegate: self
      )
    )
    searchController.showsSearchResultsController = false
    searchController.obscuresBackgroundDuringPresentation = false

    navigationItem.title = "探す"
    navigationItem.searchController = searchController

    // MARK: SearchTextFieldの設定
    let toolBar = UIToolbar()
    let rightButton = BarButtonItem(
      barButtonSystemItem: .close, target: self, action: #selector(closeKeyboard))
    let spacer = UIBarButtonItem.flexibleSpace()
    toolBar.items = [spacer, rightButton]
    toolBar.sizeToFit()
    navigationItem.searchController?.searchBar.searchTextField.inputAccessoryView = toolBar

    // MARK: configure
    configure()
  }

  @objc
  private func closeKeyboard() {
    navigationItem.searchController?.searchBar.searchTextField.resignFirstResponder()
  }

  private func configure() {

    guard let searchBar = navigationItem.searchController?.searchBar else {
      return
    }

    searchBar.rx.text.orEmpty
      .subscribe(onNext: { [weak self] text in
        self?.searchViewModel.update(text: text)
      })
      .disposed(by: disposeBag)

    let textFieldReturnKeyTapped = searchBar
      .rx
      .searchButtonClicked
      .asObservable()
      .share()

    textFieldReturnKeyTapped
      .subscribe(onNext: { [weak self] in
        self?.searchViewModel.startSearch()
      })
      .disposed(by: disposeBag)

    searchViewModel
      .searchToken
      .subscribe { event in
        guard let model = event.element else { return }

        let field = searchBar.searchTextField
        let token = UISearchToken(icon: model.iconImage, text: model.localizedWord)
        token.representedObject = model
        field.tokens = []
        field.replaceTextualPortion(of: field.textualRange, with: token, at: field.tokens.count)
      }
      .disposed(by: disposeBag)

    let isSearching = searchViewModel
      .searchStatus
      .observe(on: MainScheduler.instance)
      .map({ $0 == .searching })
      .share()

    if let searchIndicatorView = searchIndicatorView {
      isSearching
        .subscribe(onNext: { isSearching in
          if isSearching {
            searchIndicatorView.startAnimating()
          } else {
            searchIndicatorView.stopAnimating()
          }
        })
        .disposed(by: disposeBag)
    }

    searchViewModel
      .searchResultAnnotations
      .map({ annotations -> [(Double, MapAnnotation)] in
        guard let myLocation = LocationShared.default.locationManager.location else {
          return annotations.map({ (Double.greatestFiniteMagnitude, $0) })
        }
        return annotations.map({ annotation in
          let coord = CLLocationCoordinate2D(
            latitude: annotation.toilet.latitude,
            longitude: annotation.toilet.longitude
          )
          let dis = myLocation.coordinate.calculateDistance(with: coord)
          return (dis, annotation)
        }).sorted(by: { (head, tail) in
          head.0 < tail.0
        })
      })
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] annotations in
        guard let self = self else {
          return
        }
        for annotation in annotations.map(\.1) {
          if let old = self.mapView.mapView.annotations.first(where: {
            $0.coordinate == annotation.coordinate
          }) {
            self.mapView.mapView.removeAnnotation(old)
          }
          self.mapView.mapView.addAnnotation(annotation)
        }
        if let best = annotations.sorted(by: { (a, b) in
          a.0 < b.0
        }).first?.1 {
          let region = self.mapView.getDefaultRegion(of: best.coordinate)
          self.mapView.set(region: region)
          self.mapView.mapView.selectAnnotation(best, animated: true)
        }
      })
      .disposed(by: disposeBag)
  }
}
