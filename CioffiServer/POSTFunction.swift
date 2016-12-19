//
// Created by Shane Whitehead on 19/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import PromiseKit
import CioffiAPI

extension Int {
	public static func randomBetween(min: Int, max: Int) -> Int {
		let delta = max - min
		return min + Int(arc4random_uniform(UInt32(delta)))
	}
}

let postResultKey = "Key.POSTResult"

enum POSTResultType: Int {
	case unknown = 0
	case fail
	case pass

	static var random: POSTResultType {
		return POSTResultType(rawValue: Int.randomBetween(min: 0, max: 4))!
	}
}

enum POSTComponent {
	case batteryPresence
	case chargerFault
	case pcbTempSensors
	case radommeTempSensors
	case batteryTempSensors
	case gnssFeed
	case wifiInterface
	case satellite
	case cellular

	static let all: [POSTComponent] = [
		.batteryPresence,
		.chargerFault,
		.pcbTempSensors,
		.radommeTempSensors,
		.batteryTempSensors,
		.gnssFeed,
		.wifiInterface,
		.satellite,
		.cellular,
	]
}

struct POSTReport {

	var results: [POSTComponent: POSTResultType] = [:]

	func result(`for` component: POSTComponent) -> POSTResultType {
		return results[component] ?? .unknown
	}
}

public enum APIPostReportError: Error {
	case missingBattery
	case missingCharger
	case missingPCBTemp
	case missingRadommeTemp
	case missingBatteryTemp
	case missingGNSSFeed
	case missingWiFiInterface
	case missingSatellite
	case missingCellular

	case unknownResult(value: Int)
}

class POSTResultFunction: DefaultAPIFunction {

	typealias KeyComponent = (String, POSTComponent, Error)

	struct Key {
		static let testResult = "testresult"
		static let runtimeTest = "runtimeTest"

		static let batteryPresence: KeyComponent = (key: "batteryPresence", component: POSTComponent.batteryPresence, error: APIPostReportError.missingBattery)
		static let chargerFault: KeyComponent = (key: "chargerFault", component: POSTComponent.chargerFault, error: APIPostReportError.missingCharger)
		static let pcbTempSensors: KeyComponent = (key: "pcbTempSensors", component: POSTComponent.pcbTempSensors, error: APIPostReportError.missingPCBTemp)
		static let radommeTempSensors: KeyComponent = (key: "radommeTempSensors", component: POSTComponent.radommeTempSensors, error: APIPostReportError.missingRadommeTemp)
		static let batteryTempSensors: KeyComponent = (key: "batteryTempSensors", component: POSTComponent.batteryTempSensors, error: APIPostReportError.missingBatteryTemp)
		static let gnssFeed: KeyComponent = (key: "GNSSFeed", component: POSTComponent.gnssFeed, error: APIPostReportError.missingGNSSFeed)
		static let wifiInterface: KeyComponent = (key: "wifiInterface", component: POSTComponent.wifiInterface, error: APIPostReportError.missingWiFiInterface)
		static let satellite: KeyComponent = (key: "satellite", component: POSTComponent.satellite, error: APIPostReportError.missingSatellite)
		static let cellular: KeyComponent = (key: "cellular", component: POSTComponent.cellular, error: APIPostReportError.missingCellular)

		static let keys: [KeyComponent] = [
				Key.batteryPresence,
				Key.chargerFault,
				Key.pcbTempSensors,
				Key.radommeTempSensors,
				Key.batteryTempSensors,
				Key.gnssFeed,
				Key.wifiInterface,
				Key.satellite,
				Key.cellular
		]
	}

	var postReport: [String: Any] {
		var postReport: POSTReport!
		if let report = DataModelManager.shared.get(forKey: postResultKey) as? POSTReport {
			postReport = report
		} else {
			postReport = POSTReport()
			for key in Key.keys {
				postReport.results[key.1] = POSTResultType.random
			}

			DataModelManager.shared.set(value: postReport,
					forKey: postResultKey)
		}
		var result: [String: Any] = [:]
		for (keyValue, component, error) in Key.keys {
			result[keyValue] = postReport.result(for: component).rawValue
		}
		return [Key.testResult: result]
	}

	var realTimeReport: [String: Any] {
		var postReport: POSTReport = POSTReport()
		for key in Key.keys {
			postReport.results[key.1] = POSTResultType.random
		}

		var result: [String: Any] = [:]
		for (keyValue, component, error) in Key.keys {
			result[keyValue] = postReport.result(for: component).rawValue
		}
		return [Key.testResult: result]
	}
}

class GetPOSTResult: POSTResultFunction {

	override init() {
		super.init()

		var report = POSTReport()
		for key in Key.keys {
			report.results[key.1] = POSTResultType.random
		}

		DataModelManager.shared.set(value: report,
				forKey: postResultKey)

		self.responseType = .getPOSTResults
		self.requestType = .getPOSTResults
	}

	override func body(preProcessResult: Any?) -> [String: Any] {
		return postReport
	}

}

class GetRealTimeResult: POSTResultFunction {

	override init() {
		super.init()
		self.responseType = .getRealTimeResults
		self.requestType = .getRealTimeResults
	}

	override func body(preProcessResult: Any?) -> [String: Any] {
		return realTimeReport
	}

}
