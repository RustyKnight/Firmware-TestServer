//
//  ServiceProvider.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI



struct ServiceProviderUtility {
	static func body() -> [String : Any] {
		var body: [String : Any] = [:]
		switch ModemModule.current {
		case .cellular:
			body["cellular"] = [
				"provider": DataModelManager.shared.get(forKey: DataModelKeys.serviceProvider,
				                                        withDefault: "")
			]
		case .satellite:
			body["satellite"] = [
				"provider": DataModelManager.shared.get(forKey: DataModelKeys.serviceProvider,
				                                        withDefault: "")
			]
		case .unknown: break
		}
		
		return body
	}
}

class GetServiceProvideFunction: DefaultAPIFunction {
	
	override init() {
		super.init()
		requestType = .getServiceProviderName
		responseType = .getServiceProviderName
		
		DataModelManager.shared.set(value: "Optus",
		                            forKey: DataModelKeys.serviceProvider)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		return ServiceProviderUtility.body()
	}
	
}

struct ServiceProviderNotification: APINotification {
	var type: NotificationType {
		return .serviceProvider
	}
	
	var body: [String : Any] {
		return ServiceProviderUtility.body()
	}
}
