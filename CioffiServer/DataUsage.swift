//
// Created by Shane Whitehead on 19/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import PromiseKit
import CioffiAPI


struct DataUsage {

	var satelliteStandardData: Int
	var satelliteStreamingTime: TimeInterval
	var cellularData: Int

}

fileprivate struct Key {
	static let group = "data_usage"
	static let satelliteStandardData = "satellite_standard_data"
	static let satelliteStreamingTime = "satellite_streaming_time"
	static let cellularData = "cellular_data"

	static let defaultUsage: DataUsage = DataUsage(satelliteStandardData: 100,
			satelliteStreamingTime: 200.0,
			cellularData: 300)

	static var currentState: [String: Any] {
		var body: [String: Any] = [:]
		let usage: DataUsage = DataModelManager.shared.get(forKey: DataModelKeys.dataUsage,
				withDefault: defaultUsage)

		body[Key.group] = [
			Key.satelliteStandardData: usage.satelliteStandardData,
			Key.satelliteStreamingTime: usage.satelliteStreamingTime,
			Key.cellularData: usage.cellularData
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
