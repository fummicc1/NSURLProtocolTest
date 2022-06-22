//
//  SearchResultCell.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2022/04/09.
//

import Foundation
import MapKit
import UIKit

class SearchResultCell: UICollectionViewCell {

  private var annotation: ToiletMapAnnotation?
  private var onPress: (() -> Void)?

  private weak var infoStackView: UIStackView?

  private weak var titleLabel: UILabel?
  private weak var detailLabel: UILabel?
  private weak var distanceLabel: UILabel?
  private weak var mapView: ToiletMapView?

  override func layoutSubviews() {
    super.layoutSubviews()
    contentView.layer.cornerRadius = 4
    contentView.layer.borderWidth = 1
    contentView.layer.borderColor = AppColor.mainColor.cgColor
  }

  func configure(
    toilet: ToiletPresentable,
    distance: Double,
    onPress: @escaping () -> Void
  ) {

    self.onPress = onPress

    defer {

      let tapGesture = UITapGestureRecognizer(
        target: self,
        action: #selector(_onPress)
      )
      isUserInteractionEnabled = true
      addGestureRecognizer(tapGesture)

      let region = MKCoordinateRegion(
        center: toilet.coordinate,
        latitudinalMeters: 20,
        longitudinalMeters: 20
      )
      mapView?.set(region: region)
      // only view-mode
      mapView?.isUserInteractionEnabled = false
    }

    let annotation = ToiletMapAnnotation(toilet: toilet, distance: distance)

    if mapView != nil {
      update(annotation: annotation, distance: distance)
      return
    }

    let mapView = ToiletMapView()

    mapView.add(annotation: annotation)
    mapView.show(annotations: [annotation])

    contentView.addSubview(mapView)

    mapView.snp.makeConstraints { make in
      make.top.bottom.leading.trailing.equalToSuperview()
    }

    self.mapView = mapView
    self.annotation = annotation
  }

  private func update(annotation: ToiletMapAnnotation, distance: Double) {
    mapView?.remove(annotations: mapView?.annotationsData ?? [])
    mapView?.show(annotations: [annotation])

    self.annotation = annotation
  }

  private func updateDisplayInfo(
    title: String,
    detail: String?,
    distance: Double
  ) {
    let isNew = infoStackView == nil
    let infoStackView = self.infoStackView ?? UIStackView()
    infoStackView.distribution = .fillProportionally
    infoStackView.axis = .horizontal
    infoStackView.spacing = 4

    if isNew {
      contentView.addSubview(infoStackView)
      infoStackView.snp.makeConstraints { make in
        make.leading.trailing.top.bottom.equalToSuperview()
      }
    }

    if let titleLabel = titleLabel {
      infoStackView.removeArrangedSubview(titleLabel)
      titleLabel.removeFromSuperview()
    }
    if let detailLabel = detailLabel {
      infoStackView.removeArrangedSubview(detailLabel)
      detailLabel.removeFromSuperview()
    }
    if let distanceLabel = distanceLabel {
      infoStackView.removeArrangedSubview(distanceLabel)
      distanceLabel.removeFromSuperview()
    }

    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .title3)

    let titleDivider = DividerView(
      length: .greatestFiniteMagnitude,
      axis: .vertical
    )
    infoStackView.addArrangedSubview(titleDivider)

    if let detail = detail {
      let detailLabel = UILabel()
      detailLabel.text = detail
      detailLabel.adjustsFontSizeToFitWidth = false
      detailLabel.lineBreakMode = .byTruncatingTail
      detailLabel.font = .preferredFont(forTextStyle: .body)
      infoStackView.addArrangedSubview(detailLabel)

      let detailDivider = DividerView(
        length: .greatestFiniteMagnitude,
        axis: .vertical
      )
      infoStackView.addArrangedSubview(detailDivider)

      self.detailLabel = detailLabel
    }

    let distanceLabel = UILabel()
    distanceLabel.text = "\(Int(distance))" + "m"
    distanceLabel.font = .preferredFont(forTextStyle: .body)

    let distanceDivider = DividerView(
      length: .greatestFiniteMagnitude,
      axis: .vertical
    )
    infoStackView.addArrangedSubview(distanceDivider)

    self.infoStackView = infoStackView
    self.titleLabel = titleLabel
    self.distanceLabel = distanceLabel
  }

  @objc
  private func _onPress() {
    onPress?()
  }
}
