//
//  ToiletMapAnnotationView.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/09.
//

import CoreLocation
import Foundation
import MapKit
import UIKit

class ToiletMapAnnotationView: MKMarkerAnnotationView {
  override func prepareForReuse() {
    super.prepareForReuse()
    glyphImage = nil
  }
}

class ToiletRouteStepAnnotationView: MKMarkerAnnotationView {
  //
  //    var titleLabel: UILabel
  //
  //    init(annotation: ToiletRouteStepAnnotation, reuseIdentifier: String) {
  //
  //        if let title = annotation.title {
  //            titleLabel = UILabel()
  //            titleLabel.backgroundColor = .clear
  //            titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
  //            titleLabel.text = title
  //            titleLabel.sizeToFit()
  //        }
  //
  //        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
  //
  //        addSubview(titleLabel)
  //    }
  //
  //    required init?(coder aDecoder: NSCoder) {
  //        fatalError("init(coder:) has not been implemented")
  //    }
  //
  //    override func layoutSubviews() {
  //        super.layoutSubviews()
  //        titleLabel.frame = CGRect(x: 0, y: bounds.height - 40, width: , height: 40)
  //    }
  //
}
