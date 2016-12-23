//
// Created by Shane Whitehead on 23/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI
import SwiftyJSON

fileprivate struct Key {
	static let group = "unreadmessages"
	static let count = "count"

	static var currentState: [String: Any] {
		let count: Int = DataModelManager.shared.get(forKey: DataModelKeys.unreadMessageCount,
				withDefault: 0)
		var body: [String: Any] = [:]

		body[Key.group] = [
				Key.count: count
		]
		return body
	}
}

class UnreadMessageCountFunction: DefaultAPIFunction {

	override func body(preProcessResult: Any?) -> [String: Any] {
		return Key.currentState
	}

}

class GetUnreadMessageCountFunction: UnreadMessageCountFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: 0,
				forKey: DataModelKeys.unreadMessageCount)

		self.responseType = .getUnreadMessageCount
		self.requestType = .getUnreadMessageCount
	}

}

struct UnreadMessageCountNotification: APINotification {

	var type: NotificationType {
		return .unreadMessages
	}

	var body: [String : Any] {
		return Key.currentState
	}

	init() {
	}

}

class ClearUnreadMessageCountFunction: UnreadMessageCountFunction {

	override init() {
		super.init()

		self.responseType = .clearUnreadMessageCount
		self.requestType = .clearUnreadMessageCount
	}

	override func body(preProcessResult: Any?) -> [String: Any] {
		return [:]
	}
}
