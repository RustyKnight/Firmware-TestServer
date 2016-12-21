//
// Created by Shane Whitehead on 19/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import PromiseKit
import CioffiAPI

let simStatusKey = "Key.SIMStatus"
let simPINKey = "Key.SIMPIN"

enum SIMStatus: Int {
	case unlocked = 0
	case pinLocked
	case pukLocked
	case simMissing
}

fileprivate struct Key {
	static let group = "sim"
	static let status = "status"

	static let currentPin = "currentpin"
	static let newPin = "newpin"

	static var currentState: [String: Any] {
		let status: SIMStatus = DataModelManager.shared.get(forKey: simStatusKey,
				withDefault: SIMStatus.pinLocked)
		return with(status: status)
	}

	static func with(status: SIMStatus) -> [String: Any] {
		var body: [String: Any] = [:]

		body[Key.group] = [
				Key.status: status.rawValue
		]
		return body
	}

	static func notify(with status: SIMStatus) {
		_ = after(interval: 1.0).then { () -> Void in
			do {
				try Server.default.send(notification: SIMStatusNotification(status))
			} catch let error {
				log(error: "\(error)")
			}
		}
	}
}

class SIMStatusFunction: DefaultAPIFunction {

	override func body(preProcessResult: Any?) -> [String: Any] {
		return Key.currentState
	}

}

class GetSIMStatusFunction: SIMStatusFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: SIMStatus.unlocked,
				forKey: simStatusKey)

		self.responseType = .getSIMStatus
		self.requestType = .getSIMStatus
	}

}

class SetSIMPinFunction: SIMStatusFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: "",
				forKey: simPINKey)

		self.responseType = .setSIMPIN
		self.requestType = .setSIMPIN
	}

	override func preProcess(request: JSON) -> PreProcessResult {
		guard let currentPin = request[Key.group][Key.currentPin].string else {
			log(error: "Missing current pin")
			return createResponse(type: .accessDenied)
		}

		let masterPin: String = DataModelManager.shared.get(forKey: simPINKey, withDefault: "")
		guard masterPin == currentPin else {
			log(error: "PIN mismatch")
			return createResponse(type: .accessDenied)
		}

		guard let newPin = request[Key.group][Key.newPin].string else {
			log(error: "Missing new pin")
			return createResponse(type: .accessDenied)
		}

		DataModelManager.shared.set(value: newPin,
				forKey: simPINKey)

		// Does this lock/unlock the SIM?

		return createResponse(type: .success)
	}


}

class UnlockSIMFunction: SIMStatusFunction {

	override init() {
		super.init()

		self.responseType = .unlockSIM
		self.requestType = .unlockSIM
	}

	override func preProcess(request: JSON) -> PreProcessResult {
		guard let currentPin = request[Key.currentPin].string else {
			log(error: "Missing current pin")
			return createResponse(type: .accessDenied)
		}

		let masterPin: String = DataModelManager.shared.get(forKey: simPINKey, withDefault: "")
		guard masterPin == currentPin else {
			log(error: "PIN mismatch")
			return createResponse(type: .accessDenied)
		}

		DataModelManager.shared.set(value: SIMStatus.unlocked,
				forKey: simStatusKey)

		Key.notify(with: SIMStatus.unlocked)

		return createResponse(type: .success)
	}

}

struct SIMStatusNotification: APINotification {

	var type: NotificationType {
		return .simStatus
	}

	var body: [String : Any] {
		return Key.with(status: status)
	}

	let status: SIMStatus

	init(_ status: SIMStatus) {
		self.status = status
	}

}
