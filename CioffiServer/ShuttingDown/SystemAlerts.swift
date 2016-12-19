//
//  SystemAlerts.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI

enum SystemAlertType: Int {
	case powerButtonPressed = 0
	case criticalHighTemperature = 1
	case criticalLowTemperature = 2
	case batteryFlat = 3
}

struct SystemAlertNotification: APINotification {
	var type: NotificationType {
		return .systemAlerts
	}

	var body: [String: Any] {
		var data: [String: Any] = [:]
		data["alert"] = [
				"type": alertType.rawValue
		]
		return data
	}

	let alertType: SystemAlertType

	init(type: SystemAlertType) {
		alertType = type
	}
}

fileprivate struct Key {
	static let group = "alerts"
	static let type = "type"

	static var currentState: [String: Any] {
		var body: [String: Any] = [:]

		body[Key.group] = [
				Key.type: [SystemAlertType.criticalHighTemperature, SystemAlertType.batteryFlat]
		]
		return body
	}
}

class SystemAlertsFunction: DefaultAPIFunction {

	override func body(preProcessResult: Any?) -> [String: Any] {
		return Key.currentState
	}

}

class GetSystemAlertsFunction: SystemAlertsFunction {

	override init() {
		super.init()

		self.responseType = .getSystemAlerts
		self.requestType = .getSystemAlerts
	}

}

