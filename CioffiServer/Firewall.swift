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

enum FirewallOption: Int {
	case off = 0
	case blackList
	case whiteList
}

struct FirewallEntry {
	var portType: FirewallPortType
	var fromPort: Int
	var toPort: Int
	var `protocol`: FirewallProtocol
	var ipAddress: String
}

struct FirewallSetting {
	var option: FirewallOption
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
		let setting: FirewallSetting = DataModelManager.shared.get(forKey: dataModelKey.rawValue,
				withDefault: FirewallSetting(option: .off, entries: []))

		body["state"] = setting.option.rawValue
		let entries = setting.entries.map { entry -> [String: Any] in
			return [
					"porttype": entry.portType.rawValue,
					"fromport": entry.fromPort,
					"toport": entry.toPort,
					"protocol": entry.protocol.rawValue,
					"ipaddress": entry.ipAddress
			]
		}
		body["entries"] = entries
		return ["firewall": body]
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
				let option = FirewallOption(rawValue: stateValue) else {
			log(error: "Missing \"state\" entry")
			return createResponse(success: false)
		}
		guard let rawEntries = request["firewall"]["entries"].array else {
			log(error: "Missing \"entries\" entry")
			return createResponse(success: false)
		}

		var firewallEntries: [FirewallEntry] = []
		do {
			firewallEntries = try rawEntries.map { json -> FirewallEntry in
				guard let portTypeValue = json["porttype"].int,
				      let portType = FirewallPortType(rawValue: portTypeValue) else {
					log(error: "Missing \"porttype\" entry")
					throw ParseError.thatSucks
				}
				guard let fromPort = json["fromport"].int else {
					log(error: "Missing \"fromport\" entry")
					throw ParseError.thatSucks
				}
				guard let toPort = json["toport"].int else {
					log(error: "Missing \"toport\" entry")
					throw ParseError.thatSucks
				}
				guard let protocolValue = json["protocol"].int,
				      let firewallProtocol = FirewallProtocol(rawValue: protocolValue) else {
					log(error: "Missing \"protocol\" entry")
					throw ParseError.thatSucks
				}
				guard let ipAddress = json["ipaddress"].string else {
					log(error: "Missing \"ipaddress\" entry")
					throw ParseError.thatSucks
				}
				return FirewallEntry(portType: portType,
						fromPort: fromPort,
						toPort: toPort,
						protocol: firewallProtocol,
						ipAddress: ipAddress)
			}
		} catch {
			return createResponse(success: false)
		}
		let setting = FirewallSetting(option: option,
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

class GetInboundFirewall: GetFirewall {

	init() {
		super.init(responseType: .getInboundFirewall,
				requestType: .getInboundFirewall,
				dataModelKey: .outbound)
	}

}

class SetInboundFirewall: SetFirewall {

	init() {
		super.init(responseType: .setInboundFirewall,
				requestType: .setInboundFirewall,
				dataModelKey: .outbound)
	}

}
