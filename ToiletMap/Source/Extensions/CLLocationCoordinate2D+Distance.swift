//
//  CLLocationCoordinate2D+Distance.swift
//  ToiletMap
//
//  Created by Fumiya Tanaka on 2020/01/07.
//

import CoreLocation
import Foundation
import MapKit

extension CLLocationCoordinate2D {

  func calculateDistance(with destination: CLLocationCoordinate2D) -> CLLocationDistance {
    let startPoint = MKMapPoint(self)
    let destinationPoint = MKMapPoint(destination)
    let distance = startPoint.distance(to: destinationPoint)
    return distance
  }

}
