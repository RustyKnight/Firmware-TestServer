//
// Created by Shane Whitehead on 19/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import PromiseKit
import CioffiAPI

public enum SIMStatusError: Error {
	case missingLockStatus
	case invalidLockStatus(value: Int)
	case missingPresenceStatus
	case invalidPresenceStatus(value: Int)
	case missingPINStatus
	case invalidPINStatus(value: Int)
}

public enum SIMPresenceStatus: Int {
	case unknown = 0
	case missing
	case present
}

public enum SIMLockStatus: Int {
	case unknown = 0
	case unlocking
	case pinLocked
	case pukLocked
	case unlocked
}

public enum SIMPINStatus: Int {
	case unknown = 0
	case enabled
	case enabling
	case disabled
	case disabling
}

struct SIMStatus {
	var presenceStatus: SIMPresenceStatus
	var lockStatus: SIMLockStatus
	var pinStatus: SIMPINStatus
}

fileprivate struct Key {

	static let defaultStatus = SIMStatus(presenceStatus: .present, lockStatus: .pinLocked, pinStatus: .enabled)

	static let sim = "sim"
	static let pin = "pin"
	static let currentPin = "currentPin"
	static let newPin = "newPin"
	static let present = "present"
	static let lockStatus = "status"
	static let pinStatus = "enableStatus"
	static let enabled = "enabled"

	static var currentStatus: SIMStatus {
		get {
			return DataModelManager.shared.get(forKey: DataModelKeys.simStatus, withDefault: defaultStatus)
		}

		set {
			DataModelManager.shared.set(value: newValue, forKey: DataModelKeys.simStatus, withNotification: true)
		}
	}

	static var currentState: [String: Any] {
		let status: SIMStatus = DataModelManager.shared.get(forKey: DataModelKeys.simStatus,
				withDefault: defaultStatus)
		return with(status: status)
	}

	static func with(status: SIMStatus) -> [String: Any] {
		var body: [String: Any] = [:]

		body[sim] = [
				present: status.presenceStatus.rawValue,
				lockStatus: status.lockStatus.rawValue,
				pinStatus: status.pinStatus.rawValue
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

		DataModelManager.shared.set(value: Key.defaultStatus,
				forKey: DataModelKeys.simStatus)

		self.responseType = .getSIMStatus
		self.requestType = .getSIMStatus
	}

}

class SetSIMPinFunction: SIMStatusFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: "0000",
				forKey: DataModelKeys.simPIN)

		self.responseType = .setSIMPIN
		self.requestType = .setSIMPIN
	}

	override func preProcess(request: JSON) -> PreProcessResult {
		guard let currentPin = request[Key.sim][Key.currentPin].string else {
			log(error: "Missing current pin")
			return createResponse(type: .accessDenied)
		}

		let masterPin: String = DataModelManager.shared.get(forKey: DataModelKeys.simPIN, withDefault: "0000")
		guard masterPin == currentPin else {
			log(error: "PIN mismatch")
			return createResponse(type: .accessDenied)
		}

		guard let newPin = request[Key.sim][Key.newPin].string else {
			log(error: "Missing new pin")
			return createResponse(type: .accessDenied)
		}

		guard newPin.isEmptyWhenTrimmed else {
			DataModelManager.shared.set(value: newPin,
					forKey: DataModelKeys.simPIN)
			return createResponse(type: .success)

		}

		guard let enabled = request[Key.sim][Key.enabled].bool else {
			return createResponse(type: .failed)
		}

		var status = Key.currentStatus
		guard status.pinStatus == .enabled || status.pinStatus == .disabled else {
			return createResponse(type: .failed)
		}

		status.pinStatus = enabled ? .enabling : .disabling
		Key.currentStatus = status

		Key.notify(with: status)

		after(interval: 5.0).then { () -> Void in
			var status = Key.currentStatus
			status.pinStatus = enabled ? .enabled : .disabled
			Key.currentStatus = status

			Key.notify(with: status)
		}

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
		log(info: request.stringValue)
		guard let currentPin = request[Key.sim][Key.pin].string else {
			log(error: "Missing current pin")
			return createResponse(type: .accessDenied)
		}

		let masterPin: String = DataModelManager.shared.get(forKey: DataModelKeys.simPIN, withDefault: "0000")
		log(info: "masterPin = \(masterPin); currentPin = \(currentPin)")
		guard masterPin == currentPin else {
			log(error: "PIN mismatch")
			return createResponse(type: .accessDenied)
		}

		var status = Key.currentStatus
		status.lockStatus = .unlocked
		Key.currentStatus = status

		Key.notify(with: status)

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
