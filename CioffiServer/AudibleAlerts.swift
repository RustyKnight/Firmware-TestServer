//
// Created by Shane Whitehead on 19/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import PromiseKit
import CioffiAPI

enum AudibleAlertOption: Int {
	case off = 0
	case low
	case high
}

let audibleAlertOptionKey = "Key.AudibleAlertOption"

fileprivate struct Key {
	static let group = "audiblealert"
	static let status = "status"

	static var currentState: [String: Any] {
		var body: [String: Any] = [:]
		let status: AudibleAlertOption = DataModelManager.shared.get(forKey: audibleAlertOptionKey,
				withDefault: AudibleAlertOption.off)

		body[Key.group] = [
				Key.status: status.rawValue
		]
		return body
	}
}

class AudibleAlertsFunction: DefaultAPIFunction {

	override func body(preProcessResult: Any?) -> [String: Any] {
		return Key.currentState
	}

}

class GetAudibleAlertsFunction: AudibleAlertsFunction {

	override init() {
		super.init()

		self.responseType = .getAudibleAlertOption
		self.requestType = .getAudibleAlertOption
	}

}

class SetAudibleAlertsFunction: AudibleAlertsFunction {

	override init() {
		super.init()

		self.responseType = .setAudibleAlertOption
		self.requestType = .setAudibleAlertOption
	}

	override func preProcess(request: JSON) -> PreProcessResult {
		guard let statusValue = request[Key.group][Key.status].int else {
			return createResponse(type: .failed)
		}
		guard let option = AudibleAlertOption(rawValue: statusValue) else {
			return createResponse(type: .failed)
		}
		DataModelManager.shared.set(value: option, forKey: audibleAlertOptionKey)
		return createResponse(type: .success)
	}


}
