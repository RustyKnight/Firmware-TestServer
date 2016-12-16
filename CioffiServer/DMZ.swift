//
// Created by Shane Whitehead on 16/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

public struct DMZ {
	public let isEnabled: Bool
	public let ipAddress: String

	public init(isEnabled: Bool, ipAddress: String) {
		self.isEnabled = isEnabled
		self.ipAddress = ipAddress
	}
}

let dmzKey = "Key.dmz"

class DMZFunction: DefaultAPIFunction {

	struct Key {
		static let group = "dmz"
		static let enabled = "enabled"
		static let ipAddress = "ipaddress"
	}

	static let defaultValue = DMZ(isEnabled: false, ipAddress: "0.0.0.0")

	override func body(preProcessResult: Any?) -> [String: Any] {
		var body: [String: Any] = [:]
		let config = DataModelManager.shared.get(forKey: dmzKey,
				withDefault: DMZFunction.defaultValue)

		body[Key.enabled] = config.isEnabled
		body[Key.ipAddress] = config.ipAddress
		return [Key.group: body]
	}

}

class GetDMZ: DMZFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: DMZ(isEnabled: false, ipAddress: "0.0.0.0"),
				forKey: dmzKey)

		self.responseType = .getDMZ
		self.requestType = .getDMZ
	}

}

class SetDMZ: DMZFunction {

	override init() {
		super.init()

		self.responseType = .setDMZ
		self.requestType = .setDMZ
	}

	override func preProcess(request: JSON) -> PreProcessResult {
		guard let isEnabled = request[Key.group][Key.enabled].bool else {
			log(error: "Missing enabled state")
			return createResponse(success: false)
		}
		guard let ipAddress = request[Key.group][Key.ipAddress].string else {
			log(error: "Missing ip address")
			return createResponse(success: false)
		}

		let config = DMZ(isEnabled: isEnabled, ipAddress: ipAddress)
		DataModelManager.shared.set(value: config,
				forKey: dmzKey)
		return createResponse(success: true)
	}

}