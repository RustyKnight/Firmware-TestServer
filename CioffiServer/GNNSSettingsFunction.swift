//
// Created by Shane Whitehead on 19/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import PromiseKit
import CioffiAPI

let gnssSettingKey = "Key.gnnsSetting"

enum GNSSOption: Int {
	case none = 0
	case beidou
	case glonass
	case gps
}

struct DefaultGNSSSetting {
	public let preferred: GNSSOption
	public let secondary: GNSSOption
}


fileprivate struct Key {
	static let group = "gnss"
	static let preferred = "preferred"
	static let secondary = "secondary"

	static let defaultValue = DefaultGNSSSetting(preferred: .glonass, secondary: .glonass)

	static var currentState: [String: Any] {
		let setting: DefaultGNSSSetting = DataModelManager.shared.get(forKey: gnssSettingKey,
				withDefault: defaultValue)
		return with(setting: setting)
	}

	static func with(setting: DefaultGNSSSetting) -> [String: Any] {
		var body: [String: Any] = [:]

		body[Key.group] = [
				Key.preferred: setting.preferred.rawValue,
				Key.secondary: setting.secondary.rawValue
		]
		return body
	}

}

class GNSSSettingFunction: DefaultAPIFunction {

	override func body(preProcessResult: Any?) -> [String: Any] {
		return Key.currentState
	}

}

class GetGNSSSettingFunction: GNSSSettingFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: Key.defaultValue,
				forKey: gnssSettingKey)

		self.responseType = .getGNSSSetting
		self.requestType = .getGNSSSetting
	}

}

class SetGNSSSettingFunction: GNSSSettingFunction {

	override init() {
		super.init()

		self.responseType = .setGNSSSetting
		self.requestType = .setGNSSSetting
	}

	override func preProcess(request: JSON) -> PreProcessResult {
		guard let preferredValue = request[Key.preferred].int else {
			log(error: "Missing preferred setting")
			return createResponse(type: .failed)
		}
		guard let preferred = GNSSOption(rawValue: preferredValue) else {
			log(error: "Invalid preferred setting (\(preferredValue))")
			return createResponse(type: .failed)
		}
		guard preferred != .none else {
			log(error: "Invalid preferred setting (\(preferred))")
			return createResponse(type: .failed)
		}
		guard let secondaryValue = request[Key.secondary].int else {
			log(error: "Missing secondary setting")
			return createResponse(type: .failed)
		}
		guard let secondary = GNSSOption(rawValue: secondaryValue) else {
			log(error: "Invalid secondary setting (\(secondaryValue))")
			return createResponse(type: .failed)
		}

		let setting = DefaultGNSSSetting(preferred: preferred, secondary: secondary)
		DataModelManager.shared.set(value: setting,
				forKey: gnssSettingKey)

		return createResponse(type: .success)
	}


}
