//
// Created by Shane Whitehead on 19/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import PromiseKit
import CioffiAPI

enum CallStatus: Int {
	case inactive = 0
	case outgoing
	case incoming
}

fileprivate struct Key {
	static let group = "callstatus"
	static let callStatus = "value"

	static var currentState: [String: Any] {
		var body: [String: Any] = [:]
		let status: CallStatus = DataModelManager.shared.get(forKey: DataModelKeys.callStatus,
				withDefault: CallStatus.inactive)

		body[Key.callStatus] = status.rawValue
		return [Key.group: body]
	}
}

class CallStatusFunction: DefaultAPIFunction {

	override func body(preProcessResult: Any?) -> [String: Any] {
		return Key.currentState
	}

}

class GetCallStatusFunction: CallStatusFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: CallStatus.inactive,
				forKey: DataModelKeys.callStatus)

		self.responseType = .getCallStatus
		self.requestType = .getCallStatus
	}

}

struct CallStatusNotification: APINotification {

	var type: NotificationType {
		return .callStatus
	}

	var body: [String : Any] {
		return Key.currentState
	}

	init(_ status: CallStatus) {
		DataModelManager.shared.set(value: status,
				forKey: DataModelKeys.callStatus)	}

}
