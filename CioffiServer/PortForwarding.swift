//
// Created by Shane Whitehead on 16/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

public struct PortForwardingConfiguration {
	public let isEnabled: Bool
	public let entries: [PortForwardingEntry]

	public init(isEnabled: Bool, entries: [PortForwardingEntry]) {
		self.isEnabled = isEnabled
		self.entries = entries
	}
}

public struct PortForwardingEntry {
	public let fromPort: Int
	public let toPort: Int
	public let ipAddress: String

	public init(fromPort: Int, toPort: Int, ipAddress: String) {
		self.fromPort = fromPort
		self.toPort = toPort
		self.ipAddress = ipAddress
	}
}

let portForwardingKey = "Key.PortForwarding"

class PortForwardingFunction: DefaultAPIFunction {

	struct Key {
		static let group = "portforwarding"
		static let enabled = "enabled"
		static let entries = "entries"

		static let fromPort = "fromport"
		static let toPort = "toport"
		static let ipAddress = "ipaddress"
	}

	static let defaultValue = PortForwardingConfiguration(isEnabled: false, entries: [])

	override func body(preProcessResult: Any?) -> [String: Any] {
		var body: [String: Any] = [:]
		let config: PortForwardingConfiguration = DataModelManager.shared.get(forKey: portForwardingKey,
				withDefault: PortForwardingFunction.defaultValue)

		body[Key.enabled] = config.isEnabled
		body[Key.entries] = config.entries.map { entry -> [String: Any] in
			return [
					Key.fromPort: entry.fromPort,
					Key.toPort: entry.toPort,
					Key.ipAddress: entry.ipAddress
			]
		}
		return [Key.group: body]
	}

}

class GetPortForwarding: PortForwardingFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: PortForwardingFunction.defaultValue,
				forKey: portForwardingKey)

		self.responseType = .getPortForwardingConfiguration
		self.requestType = .getPortForwardingConfiguration
	}

}

enum ParseError: Error {
	case thatSucks
}

class SetPortForwarding: PortForwardingFunction {

	override init() {
		super.init()

		self.responseType = .setPortForwardingConfiguration
		self.requestType = .setPortForwardingConfiguration
	}

	override func preProcess(request: JSON) -> PreProcessResult {
		guard let isEnabled = request[Key.group][Key.enabled].bool else {
			log(error: "Missing enabled state")
			return createResponse(success: false)
		}
		guard let rawEntries = request[Key.group][Key.entries].array else {
			log(error: "Missing entries")
			return createResponse(success: false)
		}

		var entries: [PortForwardingEntry] = []
		do {
			entries = try rawEntries.map { json -> PortForwardingEntry in
				guard let fromPort = json[Key.fromPort].int else {
					log(error: "Missing entry from port")
					throw ParseError.thatSucks
				}
				guard let toPort = json[Key.toPort].int else {
					log(error: "Missing entry to port")
					throw ParseError.thatSucks
				}
				guard let ipAddress = json[Key.ipAddress].string else {
					log(error: "Missing entry ip address")
					throw ParseError.thatSucks
				}

				return PortForwardingEntry(fromPort: fromPort, toPort: toPort, ipAddress: ipAddress)
			}
		} catch {
			return createResponse(success: false)
		}

		let config = PortForwardingConfiguration(isEnabled: isEnabled, entries: entries)
		DataModelManager.shared.set(value: config,
				forKey: portForwardingKey)
		return createResponse(success: true)
	}

}