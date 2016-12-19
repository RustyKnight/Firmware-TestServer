//
// Created by Shane Whitehead on 19/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import PromiseKit
import CioffiAPI

let emergencyNumberKey = "Key.EmergencyNumber"

class EmergencyNumberFunction: DefaultAPIFunction {

	struct Key {
		static let group = "network"
		static let emergencyNumber = "emergencyNumber"
	}

	override func body(preProcessResult: Any?) -> [String: Any] {
		var body: [String: Any] = [:]
		let number: String = DataModelManager.shared.get(forKey: emergencyNumberKey,
				withDefault: "")

		body[Key.emergencyNumber] = number
		return [Key.group: body]
	}

}

class GetEmergencyNumber: EmergencyNumberFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: "",
				forKey: emergencyNumberKey)

		self.responseType = .getEmergencyNumber
		self.requestType = .getEmergencyNumber
	}

}

class SetEmergencyNumber: EmergencyNumberFunction {

	override init() {
		super.init()

		self.responseType = .setEmergencyNumber
		self.requestType = .setEmergencyNumber
	}

	override func preProcess(request: JSON) -> PreProcessResult {
		guard let number = request[Key.group][Key.emergencyNumber].string else {
			log(error: "Missing emergency number")
			return createResponse(type: .failed)
		}

		DataModelManager.shared.set(value: number,
				forKey: emergencyNumberKey)

		_ = after(interval: 1.0).then { () -> Void in
			do {
				let number = DataModelManager.shared.get(forKey: emergencyNumberKey, withDefault: "")
				try Server.default.send(notification: EmergencyNumberNotification(number: number))
			} catch let error {
				log(error: "\(error)")
			}
		}
		return createResponse(type: .success)
	}

}

struct EmergencyNumberNotification: APINotification {

	struct Key {
		static let group = "network"
		static let emergencyNumber = "emergencyNumber"
	}

	var type: NotificationType {
		return .emergencyNumber
	}

	var body: [String : Any] {
		return [Key.group: [Key.emergencyNumber: number]]
	}

	let number: String

	init(number: String) {
		self.number = number
	}

}