//
// Created by Shane Whitehead on 19/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import PromiseKit
import CioffiAPI

let cellularNetworkRoamingKey = "Key.EmergencyNumber"

class CellularNetworkRoamingFunction: DefaultAPIFunction {

	struct Key {
		static let group = "network"
		static let cellularNetworkRoaming = "cellularroaming"
	}

	override func body(preProcessResult: Any?) -> [String: Any] {
		var body: [String: Any] = [:]
		let number: Bool = DataModelManager.shared.get(forKey: cellularNetworkRoamingKey,
				withDefault: false)

		body[Key.cellularNetworkRoaming] = number
		return [Key.group: body]
	}

}

class GetCellularNetworkRoamingFunction: CellularNetworkRoamingFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: "",
				forKey: portForwardingKey)

		self.responseType = .getCellularNetworkRoaming
		self.requestType = .getCellularNetworkRoaming
	}

}

class SetCellularNetworkRoamingFunction: CellularNetworkRoamingFunction {

	override init() {
		super.init()

		self.responseType = .setCellularNetworkRoaming
		self.requestType = .setCellularNetworkRoaming
	}

	override func preProcess(request: JSON) -> PreProcessResult {
		guard let state = request[Key.group][Key.cellularNetworkRoaming].bool else {
			log(error: "Missing cellular network roaming state")
			return createResponse(success: false)
		}

		DataModelManager.shared.set(value: state,
				forKey: cellularNetworkRoamingKey)

		return createResponse(success: true)
	}

}
