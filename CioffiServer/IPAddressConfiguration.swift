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

class GetIPAddressConfiguration: DefaultAPIFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: DefaultIPAddressConfiguration(ipAddress: "192.168.0.1", subnetMask: "255.255.255.0"),
				forKey: DataModelKeys.ipAddressConfiguration)

		self.responseType = .getIPAddressConfiguration
		self.requestType = .getIPAddressConfiguration
	}

	override func body(preProcessResult: Any?) -> [String: Any] {
		var body: [String: Any] = [:]
		let config = DataModelManager.shared.get(forKey: DataModelKeys.ipAddressConfiguration,
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
			return createResponse(type: .failed)
		}
		guard let subnetMask = request["ipconfig"]["subnetmask"].string else {
			log(error: "Missing Subnet Mask")
			return createResponse(type: .failed)
		}

		let config = DefaultIPAddressConfiguration(ipAddress: ipAddress, subnetMask: subnetMask)
		DataModelManager.shared.set(value: config,
				forKey: DataModelKeys.ipAddressConfiguration)
		return createResponse(type: .success)
	}

	override func body(preProcessResult: Any?) -> [String: Any] {
		var body: [String: Any] = [:]
		let config = DataModelManager.shared.get(forKey: DataModelKeys.ipAddressConfiguration,
				withDefault: DefaultIPAddressConfiguration(ipAddress: "192.168.0.1", subnetMask: "255.255.255.0"))

		body["ipaddress"] = config.ipAddress
		body["subnetmask"] = config.subnetMask
		return ["ipconfig": body]
	}

}
