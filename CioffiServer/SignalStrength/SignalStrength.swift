//
//  SignalStrength.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

struct SignalStrengthUtility {
	static func body() -> [String : Any] {
		var body: [String : Any] = [:]
		switch ModemModule.current {
		case .cellular:
			body["cellular"] = [
				"signal": DataModelManager.shared.get(forKey: DataModelKeys.signalStrength, withDefault: 0)
			]
		case .satellite:
			body["satellite"] = [
				"signal": DataModelManager.shared.get(forKey: DataModelKeys.signalStrength, withDefault: 0)
			]
		case .unknown: break
		}
		return body
	}
}

class GetSignalStrengthFunction: DefaultAPIFunction {
	
	override init() {
		super.init()
		requestType = .getSignalStrength
		responseType = .getSignalStrength
		
		DataModelManager.shared.set(value: 0, forKey: DataModelKeys.signalStrength)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		return SignalStrengthUtility.body()
	}
	
}

struct SignalStrengthNotification: APINotification {
	var type: NotificationType {
		return .signalStrength
	}
	
	var body: [String : Any] {
		return SignalStrengthUtility.body()
	}
}
