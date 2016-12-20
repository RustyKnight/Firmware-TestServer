//
// Created by Shane Whitehead on 19/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import PromiseKit
import CioffiAPI

enum APIWiFiConnectionsError: Error {
	case missingConnections
	case missingMACAddress
	case missingIPAddress
	case missingHostName
}

struct DefaultWIFIConnection {
	let macAddress: String
	let ipAddress: String
	let hostName: String
}


fileprivate struct Key {
	static let group = "wificonnection"
	static let mac = "mac"
	static let ip = "ip"
	static let hostName = "hostname"

	static var currentState: [String: Any] {
		let count = Int.randomBetween(min: 0, max: 100)
		var connections: [Any] = []

		for item in 0..<count {
			connections.append(
					[mac: makeMacAddress(),
							ip: makeIPAddress(),
							hostName: "WR-\(item)"]
			)
		}

		return [group: connections]
	}

	static func makeMacAddress() -> String {
		var parts: [String] = []
		for num in 0..<8 {
			parts.append(String(format:"%2X", Int.randomBetween(min: 0, max: 256)))
		}
		
		return parts.joined(separator: ":")
	}

	static func makeIPAddress() -> String {
		var parts: [String] = []
		for num in 0..<4 {
			parts.append(String(Int.randomBetween(min: 0, max: 256)))
		}

		return parts.joined(separator: ".")
	}
}

class WiFiConnectionsFunction: DefaultAPIFunction {

	override func body(preProcessResult: Any?) -> [String: Any] {
		return Key.currentState
	}

}

class GetWiFiConnectionsFunction: WiFiConnectionsFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: WiFiConnections.inactive,
				forKey: callStatusKey)

		self.responseType = .getWiFiConnections
		self.requestType = .getWiFiConnections
	}

}

struct WiFiConnectionsNotification: APINotification {

	var type: NotificationType {
		return .wifiConnections
	}

	var body: [String: Any] {
		return Key.currentState
	}

	init() {
	}
}