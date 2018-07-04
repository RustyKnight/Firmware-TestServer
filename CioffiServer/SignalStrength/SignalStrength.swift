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

enum RSSI: Int {
  case max = -50
  case min = -130
  
  static func random() -> Int {
    return Int.randomBetween(min: RSSI.min.rawValue, max: RSSI.max.rawValue)
  }
}

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
				"signal": DataModelManager.shared.get(forKey: DataModelKeys.signalStrength, withDefault: 0),
        "sqi": 1,
        "lqi": 0,
        "rssi": SignalStrengthUtility.rssi
			]
		case .unknown: break
		}
		return body
	}
  
  static var rssi: Int {
    guard DataModelManager.shared.get(forKey: DataModelKeys.sapaState) as? Bool ?? false else {
      return 0
    }
    return RSSI.random()
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
