//
//  AccessRestricitions.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

struct AccessRestricitionKeySet {
	let enabledKey: String
	let lockedKey: String
	let passwordKey: String
}

enum AccessRestricition: String, CustomStringConvertible {
	case admin = "admin"
	case data = "data"
	case call = "call"
	case sms = "sms"
	
	var description: String {
		return self.rawValue
	}
	
	static let values: [AccessRestricition] = [
		.admin,
		.data,
		.call,
		.sms
	]
}

let accessRestricitionKeys: [AccessRestricition: AccessRestricitionKeySet] = [
	.admin: AccessRestricitionKeySet(enabledKey: GetAccessRestricitionsFunction.adminRestricitionKey,
	                                 lockedKey: GetAccessRestricitionsFunction.adminLockedKey,
	                                 passwordKey: GetAccessRestricitionsFunction.adminPasswordKey),
	.data: AccessRestricitionKeySet(enabledKey: GetAccessRestricitionsFunction.dataRestricitionKey,
	                                lockedKey: GetAccessRestricitionsFunction.dataLockedKey,
	                                passwordKey: GetAccessRestricitionsFunction.dataPasswordKey),
	.call: AccessRestricitionKeySet(enabledKey: GetAccessRestricitionsFunction.callRestricitionKey,
	                                lockedKey: GetAccessRestricitionsFunction.callLockedKey,
	                                passwordKey: GetAccessRestricitionsFunction.callPasswordKey),
	.sms: AccessRestricitionKeySet(enabledKey: GetAccessRestricitionsFunction.smsRestricitionKey,
	                               lockedKey: GetAccessRestricitionsFunction.smsLockedKey,
	                               passwordKey: GetAccessRestricitionsFunction.smsPasswordKey),
]


class GetAccessRestricitionsFunction: DefaultAPIFunction {
	
	static let adminRestricitionKey = "adminRestricition"
	static let smsRestricitionKey = "smsRestricition"
	static let dataRestricitionKey = "dataRestricition"
	static let callRestricitionKey = "callRestricition"
	
	static let adminPasswordKey = "adminPassword"
	static let smsPasswordKey = "smsPassword"
	static let dataPasswordKey = "dataPassword"
	static let callPasswordKey = "callPassword"
	
	static let adminLockedKey = "adminLocked"
	static let smsLockedKey = "smsLocked"
	static let dataLockedKey = "dataLocked"
	static let callLockedKey = "callLocked"
	
	override init() {
		super.init()
		requestType = .getAccessRestricitions
		responseType = .getAccessRestricitions
		
		for (_, value) in accessRestricitionKeys {
			DataModelManager.shared.set(value: true, forKey: value.enabledKey)
			DataModelManager.shared.set(value: true, forKey: value.lockedKey)
			DataModelManager.shared.set(value: "cioffi", forKey: value.passwordKey)
		}
		
	}
	
	override func body() -> [String : Any] {
		var body: [String : Any] = [:]
		
		for (key, value) in accessRestricitionKeys {
			body[key.description] = [
				"restricted": DataModelManager.shared.get(forKey: value.enabledKey,
				                                          withDefault: true)
			]
		}
		return body
	}
}

class UnlockAccessRestricitionFunction: DefaultAPIFunction {
	
	override init() {
		super.init()
		requestType = .unlockAccessRestriction
		responseType = .unlockAccessRestriction
		
		for (_, value) in accessRestricitionKeys {
			DataModelManager.shared.set(value: true, forKey: value.enabledKey)
			DataModelManager.shared.set(value: true, forKey: value.lockedKey)
			DataModelManager.shared.set(value: "cioffi", forKey: value.passwordKey)
		}
	}
	
	var validated: [AccessRestricition: Bool] = [:]
	
	override func preProcess(request: JSON) {
		validated = [:]
		for (key, value) in accessRestricitionKeys {
			validated[key] = false
			guard request[key.description].exists() else {
				continue
			}
			guard let password = request[key.description]["password"].string else {
				log(warning: "Entry for, but no password for \(key)")
				continue
			}
			let currentPassword = DataModelManager.shared.get(forKey: value.passwordKey,
			                                                  withDefault: "cioffi")
			if currentPassword == password {
				validated[key] = true
				log(info: "\(key) was authenticated")
			} else {
				log(info: "\(key) failed authentication")
			}
			DataModelManager.shared.set(value: validated[key]!, forKey: value.lockedKey)
		}
	}
	
	override func body() -> [String : Any] {
		var contents: [String : Any] = [:]
		for (key, value) in validated {
			contents[key.description] = ["result": value ? 0 : 4]
		}
		return contents
	}
	
	override func handle(request: JSON, forResponder responder: Responder) throws {
		guard RequestType.from(request) == requestType else {
			throw APIFunctionError.invalidRequestType
		}
		
		preProcess(request: request)
		responder.succeeded(response: responseType, contents: body())
		//        if validated {
		//            DataModelManager.shared.set(value: false, forKey: GetAccessRestricitionsFunction.adminLockedKey)
		//            responder.succeeded(response: responseType, contents: body())
		//        } else {
		//            DataModelManager.shared.set(value: true, forKey: GetAccessRestricitionsFunction.adminLockedKey)
		//            responder.accessDenied(response: responseType)
		//        }
	}
	
}

class StopAccessFunction: DefaultAPIFunction {
	
	override init() {
		super.init()
		requestType = .stopAccess
		responseType = .stopAccess
	}
	
	override func preProcess(request: JSON) {
		guard let options = request["clear"].arrayObject else {
			return
		}
		for option in options {
			guard let option = option as? String else {
				continue
			}
			log(info: "Option = \(option)")
			guard let key = AccessRestricition.init(rawValue: option.lowercased()) else {
				continue
			}
			log(info: "key = \(key)")
			guard let keySet = accessRestricitionKeys[key] else {
				continue
			}
			log(info: "keySet.lockedKey = \(keySet.lockedKey)")
			DataModelManager.shared.set(value: false, forKey: keySet.lockedKey)
		}
	}
}
