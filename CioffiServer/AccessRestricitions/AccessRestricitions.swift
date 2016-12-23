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
	let enabledKey: DataModelKey
	let restrictedKey: DataModelKey
	let passwordKey: DataModelKey
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

class GetAccessRestricitionsFunction: DefaultAPIFunction {
	
	override init() {
		super.init()
		requestType = .getAccessRestricitions
		responseType = .getAccessRestrictions
		
		for (_, value) in DataModelKeys.accessRestrictionKeys {
			DataModelManager.shared.set(value: true, forKey: value.enabledKey)
			DataModelManager.shared.set(value: true, forKey: value.restrictedKey)
			DataModelManager.shared.set(value: "cioffi", forKey: value.passwordKey)
		}
		
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		var body: [String : Any] = [:]
		
		for (key, value) in DataModelKeys.accessRestrictionKeys {
			let value = DataModelManager.shared.get(forKey: value.restrictedKey,
			                                        withDefault: true)

			log(info: "value for \(key) = \(value)")
			body[key.description] = [
				"restricted": value
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
		
		for (_, value) in DataModelKeys.accessRestrictionKeys {
			DataModelManager.shared.set(value: true, forKey: value.enabledKey)
			DataModelManager.shared.set(value: true, forKey: value.restrictedKey)
			DataModelManager.shared.set(value: "cioffi", forKey: value.passwordKey)
		}
	}
	
	override func preProcess(request: JSON) -> PreProcessResult {
		for (key, value) in DataModelKeys.accessRestrictionKeys {
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
				DataModelManager.shared.set(value: false, forKey: value.restrictedKey)
				log(info: "\(key) was authenticated")
			} else {
				DataModelManager.shared.set(value: true, forKey: value.restrictedKey)
				log(info: "\(key) failed authentication")
			}
			log(info: "\(key) restricted == \(DataModelManager.shared.get(forKey: value.restrictedKey, withDefault: true))")
		}

		return createResponse(type: .success)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		var contents: [String : Any] = [:]
		for (key, value) in DataModelKeys.accessRestrictionKeys {
			let restricted = DataModelManager.shared.get(forKey: value.restrictedKey, withDefault: true)
			log(info: "\(key) restricted == \(restricted)")
			contents[key.description] = ["result": restricted ? 4 : 0]
		}
		return contents
	}
	
//	override func handle(request: JSON, forResponder responder: Responder) throws {
//		guard RequestType.from(request) == requestType else {
//			throw APIFunctionError.invalidRequestType
//		}
//		
//		preProcess(request: request)
//		responder.succeeded(response: responseType, contents: body())
//		//        if validated {
//		//            DataModelManager.shared.set(value: false, forKey: GetAccessRestricitionsFunction.adminLockedKey)
//		//            responder.succeeded(response: responseType, contents: body())
//		//        } else {
//		//            DataModelManager.shared.set(value: true, forKey: GetAccessRestricitionsFunction.adminLockedKey)
//		//            responder.accessDenied(response: responseType)
//		//        }
//	}
	
}

class StopAccessFunction: DefaultAPIFunction {
	
	override init() {
		super.init()
		requestType = .stopAccess
		responseType = .stopAccess
	}
	
	override func preProcess(request: JSON) -> PreProcessResult {
		guard let options = request["clear"].arrayObject else {
			return createResponse(type: .failed)
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
			guard let keySet = DataModelKeys.accessRestrictionKeys[key] else {
				continue
			}
			log(info: "keySet.restrictedKey = \(keySet.restrictedKey)")
			DataModelManager.shared.set(value: true, forKey: keySet.restrictedKey)
		}
		return createResponse(type: .success)
	}
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		var body: [String : Any] = [:]
		
		for (key, value) in DataModelKeys.accessRestrictionKeys {
			body[key.description] = [
				"restricted": DataModelManager.shared.get(forKey: value.enabledKey,
				                                          withDefault: true)
			]
		}
		return body
	}
}
