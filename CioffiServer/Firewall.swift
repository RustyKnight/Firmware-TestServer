//
// Created by Shane Whitehead on 15/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI
import SwiftyJSON

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
					"protocol": entry.protocol.rawValue,
					"ipaddress": entry.ipAddress
			]
			entries.append(entryMap)
		}
		body["entries"] = entries
		return ["firewall": body]
//		return [return"missedcalls": ["value": DataModelManager.shared.get(forKey: missedCallCountKey, withDefault: 0)]]
	}

}

class SetFirewall: DefaultAPIFunction {

	let dataModelKey: FirewallKey

	init(responseType: ResponseType, requestType: RequestType, dataModelKey: FirewallKey) {
		self.dataModelKey = dataModelKey

		super.init()

		self.responseType = responseType
		self.requestType = requestType
	}

	override func preProcess(request: JSON) -> PreProcessResult {
		guard let stateValue = request["firewall"]["state"].int,
				let state = FirewallState(rawValue: stateValue) else {
			log(error: "Missing \"state\" entry")
			return createResponse(success: false)
		}
		guard let rawEntries = request["firewall"]["entries"].array else {
			log(error: "Missing \"entries\" entry")
			return createResponse(success: false)
		}

		var firewallEntries: [FirewallEntry] = []
		for json in rawEntries {
			guard let portTypeValue = json["porttype"].int,
			      let portType = FirewallPortType(rawValue: portTypeValue) else {
				log(error: "Missing \"porttype\" entry")
				return createResponse(success: false)
			}
			guard let fromPort = json["fromport"].int else {
				log(error: "Missing \"fromport\" entry")
				return createResponse(success: false)
			}
			guard let toPort = json["toport"].int else {
				log(error: "Missing \"toport\" entry")
				return createResponse(success: false)
			}
			guard let protocolValue = json["protocol"].int,
			      let firewallProtocol = FirewallProtocol(rawValue: protocolValue) else {
				log(error: "Missing \"protocol\" entry")
				return createResponse(success: false)
			}
			guard let ipAddress = json["ipaddress"].string else {
				log(error: "Missing \"ipaddress\" entry")
				return createResponse(success: false)
			}
			firewallEntries.append(FirewallEntry(portType: portType,
					fromPort: fromPort,
					toPort: toPort,
					protocol: firewallProtocol,
					ipAddress: ipAddress))
		}
		let setting = FirewallSetting(state: state,
				entries: firewallEntries)

		DataModelManager.shared.set(value: setting, forKey: dataModelKey.rawValue)

		return createResponse(success: true)
	}

}


class GetOutboundFirewall: GetFirewall {

	init() {
		super.init(responseType: .getOutboundFirewall,
				requestType: .getOutboundFirewall,
				dataModelKey: .outbound)
	}

}

class SetOutboundFirewall: SetFirewall {

	init() {
		super.init(responseType: .setOutboundFirewall,
				requestType: .setOutboundFirewall,
				dataModelKey: .outbound)
	}

}
