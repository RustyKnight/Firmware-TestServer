//
// Created by Shane Whitehead on 8/2/17.
// Copyright (c) 2017 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import PromiseKit
import CioffiAPI

public enum SatelliteDataService: Int {
	case off = 0
	case standardIPOnly
	case standardAndStreamingIP
}

public enum CellularDataService: Int {
	case off = 0
	case on
}

struct DataService: CustomStringConvertible {
	var satelliteService: SatelliteDataService?
	var cellularService: CellularDataService?

	var description: String {
		return "satelliteService = \(satelliteService); cellularService = \(cellularService)"
	}

}

fileprivate struct DataServiceUtilities {

	static let defaultStatus = DataService(satelliteService: .off, cellularService: .off)

	static let dataService = "dataservice"
	static let satellite = "satellite"
	static let cellular = "cellular"

	static var currentStatus: DataService {
		get {
			return DataModelManager.shared.get(forKey: DataModelKeys.dataService, withDefault: defaultStatus)
		}

		set {
			DataModelManager.shared.set(value: newValue, forKey: DataModelKeys.dataService, withNotification: true)
		}
	}

	static var currentState: [String: Any] {
		let dataService = DataServiceUtilities.currentStatus
		return with(dataService)
	}

	static func with(_ status: DataService) -> [String: Any] {
		var result: [String: Any] = [:]
		if let state = status.satelliteService {
			result[DataServiceUtilities.satellite] = [DataServiceUtilities.dataService: state.rawValue]
		}
		if let state = status.cellularService {
			result[DataServiceUtilities.cellular] = [DataServiceUtilities.dataService: state.rawValue]
		}
		return result
	}

	static func notify(with status: DataService) {
		do {
			try Server.default.send(notification: DataServiceNotification(status))
		} catch let error {
			log(error: "\(error)")
		}
	}

}

class GetDataServiceFunction: DefaultAPIFunction {

	override init() {
		super.init()

		self.responseType = .getDataService
		self.requestType = .getDataService
	}

	override func body(preProcessResult: Any?) -> [String: Any] {
		return DataServiceUtilities.currentState
	}

}

class SetDataServiceFunction: DefaultAPIFunction {

	override init() {
		super.init()

		self.responseType = .setDataService
		self.requestType = .setDataService
	}

	func cellularState(from request: JSON) -> CellularDataService? {
		guard let value = request[DataServiceUtilities.cellular][DataServiceUtilities.dataService].int else {
			log(warning: "No value for cellular state")
			return nil
		}
		guard let state = CellularDataService(rawValue: value) else {
			log(warning: "Invalid value for cellular state \(value)")
			return nil
		}
		log(warning: "Cellular state will be set to \(state)")
		return state
	}

	func satelliteState(from request: JSON) -> SatelliteDataService? {
		guard let value = request[DataServiceUtilities.satellite][DataServiceUtilities.dataService].int else {
			log(warning: "No value for satellite state")
			return nil
		}
		guard let state = SatelliteDataService(rawValue: value) else {
			log(warning: "Invalid value for satellite state \(value)")
			return nil
		}
		log(warning: "Satellite state will be set to \(state)")
		return state
	}

	override func preProcess(request: JSON) -> PreProcessResult {
		var status = DataServiceUtilities.currentStatus
		log(info: "Current status = \(status)")
		status.cellularService = cellularState(from: request) ?? status.cellularService
		status.satelliteService = satelliteState(from: request) ?? status.satelliteService

		log(info: "New status = \(status)")

		DataServiceUtilities.currentStatus = status

		DataServiceUtilities.notify(with: status)

		return createResponse(type: .success)
	}

	override func body(preProcessResult: Any?) -> [String: Any] {
		return DataServiceUtilities.currentState
	}

}


struct DataServiceNotification: APINotification {

	var type: NotificationType {
		return .dataService
	}

	var body: [String : Any] {
		return DataServiceUtilities.with(status)
	}

	let status: DataService

	init(_ status: DataService) {
		self.status = status
	}

}
