//
//  MKMapView+Ex.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2021/08/08.
//

import Foundation
import MapKit
import RxSwift

extension Reactive where Base: MKMapView {
  var annotations: Binder<[MKAnnotation]> {
    Binder(base) { base, annotations in
      let current = base.annotations
      base.removeAnnotations(current)
      base.addAnnotations(annotations)
    }
  }

  var overlays: Binder<[MKOverlay]> {
    Binder(base) { base, new in
      let current = base.overlays
      base.removeOverlays(current)
      base.addOverlays(new)
    }
  }
}
