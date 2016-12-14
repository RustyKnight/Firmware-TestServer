//
// Created by Shane Whitehead on 15/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI

enum FirewallPortType: Int {
	case single = 0
	case range
	case all
}

enum FirewallProtocol: Int {
	case tcp = 0
	case udp
	case both
}

enum FirewallState: Int {
	case off = 0
	case allow
	case block
}

struct FirewallEntry {
	var portType: FirewallPortType
	var fromPort: Int
	var toPort: Int
	var `protocol`: FirewallProtocol
	var ipAddress: String
}

struct FirewallSetting {
	var state: FirewallState
	var entries: [FirewallEntry]
}

enum FirewallKey: String {
	case outbound = "Firewall.outbound"
	case inbound = "Firewall.inbound"
}

class GetFirewall: DefaultAPIFunction {

	let dataModelKey: FirewallKey

	init(responseType: ResponseType, requestType: RequestType, dataModelKey: FirewallKey) {
		self.dataModelKey = dataModelKey

		super.init()

		self.responseType = responseType
		self.requestType = requestType
	}

	override func body(preProcessResult: Any?) -> [String: Any] {
		var body: [String: Any] = [:]
		let setting = DataModelManager.shared.get(forKey: dataModelKey.rawValue,
				withDefault: FirewallSetting(state: .off, entries: []))

		body["state"] = setting.state.rawValue
		var entries: [Any] = []

		setting.entries.forEach { entry in
			let entryMap: [String: Any] = [
				"porttype": entry.portType.rawValue,
					"fromport": entry.fromPort,
					"toport": entry.toPort,
					"protocol": entry.protocol,
					"ipaddress": entry.ipAddress
			]
			entries.append(entryMap)
		}
		body["entries"] = entries
		return body
//		return [return"missedcalls": ["value": DataModelManager.shared.get(forKey: missedCallCountKey, withDefault: 0)]]
	}

}

class GetOutboundFirewall: GetFirewall {

	init() {
		super.init(responseType: .getOutboundFirewall,
				requestType: .getOutboundFirewall,
				dataModelKey: .outbound)
	}

}
