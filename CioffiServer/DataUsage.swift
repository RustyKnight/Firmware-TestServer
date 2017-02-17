//
// Created by Shane Whitehead on 19/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import PromiseKit
import CioffiAPI


struct DataUsage {

	var satelliteStandardDataTransmitted: Int
	var satelliteStandardDataReceived: Int
	var satelliteStreamingTime: TimeInterval
	var cellularDataTransmitted: Int
	var cellularDataReceived: Int

}

fileprivate struct Key {
	static let group = "data_usage"
	static let satelliteStandardDataTransmitted = "satellite_standard_data_tx"
	static let satelliteStandardDataReceived = "satellite_standard_data_rx"
	static let satelliteStreamingTime = "satellite_streaming_time"
	static let cellularDataTransmitted = "cellular_data_tx"
	static let cellularDataReceived = "cellular_data_rx"

	static let defaultUsage: DataUsage = DataUsage(
			satelliteStandardDataTransmitted: 100,
			satelliteStandardDataReceived: 350,
			satelliteStreamingTime: 200.0,
			cellularDataTransmitted: 300,
			cellularDataReceived: 800)

	static var currentState: [String: Any] {
		var body: [String: Any] = [:]
		let usage: DataUsage = DataModelManager.shared.get(forKey: DataModelKeys.dataUsage,
				withDefault: defaultUsage)

		body[Key.group] = [
				Key.satelliteStandardDataTransmitted: usage.satelliteStandardDataTransmitted,
				Key.satelliteStandardDataReceived: usage.satelliteStandardDataReceived,
				Key.satelliteStreamingTime: usage.satelliteStreamingTime,
				Key.cellularDataTransmitted: usage.cellularDataTransmitted,
				Key.cellularDataReceived: usage.cellularDataReceived
		]
		return body
	}
}

class DataUsageFunction: DefaultAPIFunction {

	override func body(preProcessResult: Any?) -> [String: Any] {
		return Key.currentState
	}

}

class GetDataUsageFunction: DataUsageFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: Key.defaultUsage,
				forKey: DataModelKeys.dataUsage)

		self.responseType = .getDataUsage
		self.requestType = .getDataUsage
	}

}
