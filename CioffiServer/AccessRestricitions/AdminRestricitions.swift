//
//  AdminRestricitions.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 10/11/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

fileprivate struct AccessRestricitionUtilities {

	static var current: [String: Any] {
		return body(for: AccessRestricition.values)
	}

	static func body(`for` services: [AccessRestricition]) -> [String: Any] {
		var body: [String : Any] = [:]
		for service in services {
			guard let keyGroup = DataModelKeys.accessRestrictionKeys[service] else {
				continue
			}
			let value = DataModelManager.shared.get(forKey: keyGroup.enabledKey,
					withDefault: true)

			body[service.description] = [
					"enabled": value
			]
		}
		return body
	}

}

class GetAdminRestriction: DefaultAPIFunction {

	override init() {
		super.init()
		requestType = .getAdminAccessRestrictions
		responseType = .getAdminAccessRestrictions
		
		for (_, value) in DataModelKeys.accessRestrictionKeys {
			DataModelManager.shared.set(value: true, forKey: value.enabledKey)
			DataModelManager.shared.set(value: "cioffi", forKey: value.passwordKey)
		}
		
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		return AccessRestricitionUtilities.current
	}

}

class SetAdminRestriction: DefaultAPIFunction {

	override init() {
		super.init()
		requestType = .setAdminAccessRestrictions
		responseType = .setAdminAccessRestrictions
	}

	var changedServices: [AccessRestricition] = []

	override func preProcess(request: JSON) -> PreProcessResult {
		changedServices.removeAll()
		for (service, value) in DataModelKeys.accessRestrictionKeys {
			let group = request[service.description]
			guard let enabled = group["enabled"].bool else {
				continue
			}
			changedServices.append(service)
			if enabled {
				guard let password = group["password"].string else {
					DataModelManager.shared.set(value: false, forKey: value.enabledKey)
					return createResponse(type: .failed)
				}
				DataModelManager.shared.set(value: true, forKey: value.enabledKey)
				DataModelManager.shared.set(value: password, forKey: value.passwordKey)
			} else {
				DataModelManager.shared.set(value: false, forKey: value.enabledKey)
			}
		}

		return createResponse(type: .success)
	}

	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		return AccessRestricitionUtilities.current
	}

	override func postProcess(request: JSON) {
		do {
			try Server.default.send(notification: AccessRestricitionNotification(changedServices))
		} catch let error {
			log(error: "\(error)")
		}
	}


}

struct AccessRestricitionNotification: APINotification {

	let services: [AccessRestricition]

	var type: NotificationType {
		return .accessRestrictionChange
	}

	var body: [String : Any] {
		return AccessRestricitionUtilities.body(for: services)
	}

	init(_ services: [AccessRestricition]) {
		self.services = services
	}

}

