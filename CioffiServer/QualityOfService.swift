//
// Created by Shane Whitehead on 16/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

public struct APIQualityOfService {
	public let isEnabled: Bool
	public let fromPort: Int
	public let toPort: Int

	public init(isEnabled: Bool, fromPort: Int, toPort: Int) {
		self.isEnabled = isEnabled
		self.fromPort = fromPort
		self.toPort = toPort
	}
}

let qosKey = "Key.qos"

class QualityOfServiceFunction: DefaultAPIFunction {

	struct Key {
		static let group = "qos"
		static let enabled = "enabled"
		static let fromPort = "fromport"
		static let toPort = "toport"
	}

	static let defaultValue = APIQualityOfService(isEnabled: false, fromPort: 0, toPort: 0)

	override func body(preProcessResult: Any?) -> [String: Any] {
		var body: [String: Any] = [:]
		let config = DataModelManager.shared.get(forKey: qosKey,
				withDefault: QualityOfServiceFunction.defaultValue)

		body[Key.enabled] = config.isEnabled
		body[Key.fromPort] = config.fromPort
		body[Key.toPort] = config.toPort
		return [Key.group: body]
	}

}

class GetQualityOfService: QualityOfServiceFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: APIQualityOfService(isEnabled: false, fromPort: 0, toPort: 0),
				forKey: qosKey)

		self.responseType = .getQualityOfService
		self.requestType = .getQualityOfService
	}

}

class SetQualityOfService: QualityOfServiceFunction {

	override init() {
		super.init()

		self.responseType = .setQualityOfService
		self.requestType = .setQualityOfService
	}

	override func preProcess(request: JSON) -> PreProcessResult {
		guard let isEnabled = request[Key.group][Key.enabled].bool else {
			log(error: "Missing enabled state")
			return createResponse(success: false)
		}
		guard let fromPort = request[Key.group][Key.fromPort].int else {
			log(error: "Missing from port")
			return createResponse(success: false)
		}
		guard let toPort = request[Key.group][Key.toPort].int else {
			log(error: "Missing from port")
			return createResponse(success: false)
		}

		let config = APIQualityOfService(isEnabled: isEnabled, fromPort: fromPort, toPort: toPort)
		DataModelManager.shared.set(value: config,
				forKey: qosKey)
		return createResponse(success: true)
	}

}