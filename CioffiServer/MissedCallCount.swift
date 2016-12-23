//
// Created by Shane Whitehead on 14/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI
import PromiseKit


class GetMissedCallCount: DefaultAPIFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: 0, forKey: DataModelKeys.missedCallCount)

		responseType = .getMissedCallCount
		requestType = .getMissedCallCount
	}

	override func body(preProcessResult: Any?) -> [String: Any] {
		return ["missedcalls": ["value": DataModelManager.shared.get(forKey: DataModelKeys.missedCallCount, withDefault: 0)]]
	}

}

class ClearMissedCallCount: DefaultAPIFunction {

	override init() {
		super.init()

		responseType = .clearMissedCallCount
		requestType = .clearMissedCallCount
	}

	override func preProcess(request: JSON) -> PreProcessResult {
		DataModelManager.shared.set(value: 0, forKey: DataModelKeys.missedCallCount)
		_ = after(interval: 1.0).then { () -> Void in
			do {
				let count = DataModelManager.shared.get(forKey: DataModelKeys.missedCallCount, withDefault: 0)
				try Server.default.send(notification: MissedCallCountNotification(count: count))
			} catch let error {
				log(error: "\(error)")
			}
		}
		return createResponse(type: .success)
	}

}

struct MissedCallCountNotification: APINotification {

	var type: NotificationType {
		return .missedCallCount
	}

	var body: [String : Any] {
		return ["missedcalls": ["value": count]]
	}

	let count: Int

	init(count: Int) {
		self.count = count
		DataModelManager.shared.set(value: count, forKey: DataModelKeys.missedCallCount)
	}

}
