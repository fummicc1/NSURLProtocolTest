//
//  CLLocationManagerTests.swift
//  ToiletMapTests
//
//  Created by Fumiya Tanaka on 2020/01/28.
//
//
//import Foundation
//import RxSwift
//import RxCocoa
//import CoreLocation
//import XCTest
//@testable import ToiletMap
//
//class CLLocationManagerTests: XCTest {
//
//}
//
//extension CLLocationManagerTests {
//
//	func test_didUpdateLocations() {
//		var completed = false
//		var location: CLLocation?
//
//		let targetLocation: CLLocation = .init(latitude: 90, longitude: 180)
//
//		autoreleasepool {
//			var manager = CLLocationManager()
//			_ = manager.rx.didUpdateLocations.subscribe (onNext: { event in
//				location = event.locations[0]
//			}, onCompleted: {
//				completed = true
//			})
//			manager.delegate?.locationManager?(manager, didUpdateLocations: [targetLocation])
//		}
//
//		XCTAssertEqual(location?.coordinate.latitude, targetLocation.coordinate.latitude)
//		XCTAssertEqual(location?.coordinate.longitude, targetLocation.coordinate.longitude)
//		XCTAssertTrue(completed)
//	}
//
//}
