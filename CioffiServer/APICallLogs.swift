//
// Created by Shane Whitehead on 14/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

class GetCallLogs: DefaultAPIFunction {

	override init() {
		super.init()

		responseType = .getCallLogs
		requestType = .getCallLogs
	}

	override func body(preProcessResult: Any?) -> [String: Any] {
		var body: [String: Any] = [:]
		var logs: [Any] = []

		for log in CallLogsManager.shared.logs {
			logs.append(log.export())
		}
		body["logs"] = logs
		return body
	}

}

class DeleteCallLogs: DefaultAPIFunction {

	override init() {
		super.init()

		responseType = .deleteCallLogs
		requestType = .deleteCallLogs
	}

	override func preProcess(request: JSON) -> PreProcessResult {
		guard let logs = request["logs"].array else {
			return createResponse(type: .failed)
		}
		for value in logs {
			guard let id = value.int else {
				log(error: "Bad log id value \(value.rawValue)")
				continue
			}
			CallLogsManager.shared.remove(id: id)
		}
		return createResponse(type: .success)
	}


	override func body(preProcessResult: Any?) -> [String: Any] {
		let body: [String: Any] = [:]
		return body
	}

}

class ClearCallLogs: DefaultAPIFunction {

	override init() {
		super.init()

		responseType = .clearCallLogs
		requestType = .clearCallLogs
	}

	override func preProcess(request: JSON) -> PreProcessResult {
		CallLogsManager.shared.clear()
		return createResponse(type: .success)
	}

}
