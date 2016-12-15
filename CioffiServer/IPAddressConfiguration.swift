//
// Created by Shane Whitehead on 16/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI
import SwiftyJSON

struct DefaultIPAddressConfiguration {

	let ipAddress: String
	let subnetMask: String

}

let ipAddressConfiguration = "Key.ipAddressConfiguration"

class GetIPAddressConfiguration: DefaultAPIFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: DefaultIPAddressConfiguration(ipAddress: "192.168.0.1", subnetMask: "255.255.255.0"),
				forKey: ipAddressConfiguration)

		self.responseType = .getIPAddressConfiguration
		self.requestType = .getIPAddressConfiguration
	}

	override func body(preProcessResult: Any?) -> [String: Any] {
		var body: [String: Any] = [:]
		let config = DataModelManager.shared.get(forKey: ipAddressConfiguration,
				withDefault: DefaultIPAddressConfiguration(ipAddress: "192.168.0.1", subnetMask: "255.255.255.0"))

		body["ipaddress"] = config.ipAddress
		body["subnetmask"] = config.subnetMask
		return ["ipconfig": body]
	}

}

class SetIPAddressConfiguration: DefaultAPIFunction {

	override init() {
		super.init()

		self.responseType = .setIPAddressConfiguration
		self.requestType = .setIPAddressConfiguration
	}

	override func preProcess(request: JSON) -> PreProcessResult {
		guard let ipAddress = request["ipconfig"]["ipaddress"].string else {
			log(error: "Missing IP Address")
			return createResponse(success: false)
		}
		guard let subnetMask = request["ipconfig"]["subnetmask"].string else {
			log(error: "Missing Subnet Mask")
			return createResponse(success: false)
		}

		let config = DefaultIPAddressConfiguration(ipAddress: ipAddress, subnetMask: subnetMask)
		DataModelManager.shared.set(value: config,
				forKey: ipAddressConfiguration)
		return createResponse(success: true)
	}

	override func body(preProcessResult: Any?) -> [String: Any] {
		var body: [String: Any] = [:]
		let config = DataModelManager.shared.get(forKey: ipAddressConfiguration,
				withDefault: DefaultIPAddressConfiguration(ipAddress: "192.168.0.1", subnetMask: "255.255.255.0"))

		body["ipaddress"] = config.ipAddress
		body["subnetmask"] = config.subnetMask
		return ["ipconfig": body]
	}

}