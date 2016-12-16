//
// Created by Shane Whitehead on 16/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

typealias MACFilteringOption = FirewallOption

struct MACAddressConfiguration {

	let option: MACFilteringOption
	let entries: [String]

	init(option: MACFilteringOption, entries: [String]) {
		self.option = option
		self.entries = entries
	}
}

let MACAddressFilteringKey = "Key.MACAddressFiltering"

class MACAddressFilteringFunction: DefaultAPIFunction {

	struct Key {
		static let group = "macfiltering"
		static let option = "state"
		static let entries = "entries"

		static let macAddress = "macaddress"
	}

	static let defaultValue = MACAddressConfiguration(option: .off, entries: [])

	override func body(preProcessResult: Any?) -> [String: Any] {
		var body: [String: Any] = [:]
		let config: MACAddressConfiguration = DataModelManager.shared.get(forKey: MACAddressFilteringKey,
				withDefault: MACAddressFilteringFunction.defaultValue)

		body[Key.option] = config.option
		body[Key.entries] = config.entries.map { entry -> [String: Any] in
			return [
					Key.macAddress: entry
			]
		}
		return [Key.group: body]
	}

}

class GetMACAddressFiltering: MACAddressFilteringFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: MACAddressFilteringFunction.defaultValue,
				forKey: MACAddressFilteringKey)

		self.responseType = .getMACAddressFilteringConfiguration
		self.requestType = .getMACAddressFilteringConfiguration
	}

}

class SetMACAddressFiltering: MACAddressFilteringFunction {

	override init() {
		super.init()

		self.responseType = .setMACAddressFilteringConfiguration
		self.requestType = .setMACAddressFilteringConfiguration
	}

	override func preProcess(request: JSON) -> PreProcessResult {
		guard let optionValue = request[Key.group][Key.option].int else {
			log(error: "Missing enabled state")
			return createResponse(success: false)
		}
		guard let option = MACFilteringOption(rawValue: optionValue) else {
			log(error: "Missing enabled state")
			return createResponse(success: false)
		}
		guard let rawEntries = request[Key.group][Key.entries].array else {
			log(error: "Missing entries")
			return createResponse(success: false)
		}

		var entries: [String] = []
		do {
			entries = try rawEntries.map { json -> String in
				guard let ipAddress = json[Key.macAddress].string else {
					log(error: "Missing entry ip address")
					throw ParseError.thatSucks
				}

				return ipAddress
			}
		} catch {
			return createResponse(success: false)
		}

		let config = MACAddressConfiguration(option: option, entries: entries)
		DataModelManager.shared.set(value: config,
				forKey: MACAddressFilteringKey)
		return createResponse(success: true)
	}

}