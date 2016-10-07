//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

let batteryChargeKey = "batteryCharge"
let batteryStatusKey = "batteryStatus"
let batteryVoltageKey = "batteryVoltage"
let batteryPresentKey = "batteryPresent"

struct BatteryStatusUtility {
	static func body() -> [String : Any] {
		var body: [String : Any] = [:]
		body["battery"] = [
			"charge": DataModelManager.shared.get(forKey: batteryChargeKey, withDefault: 0),
			"status": DataModelManager.shared.get(forKey: batteryStatusKey, withDefault: BatteryStatus.unknown).rawValue,
			"voltage": DataModelManager.shared.get(forKey: batteryVoltageKey, withDefault: 0),
			"present": DataModelManager.shared.get(forKey: batteryPresentKey, withDefault: true)
		]
		return body
	}
}

class GetBatteryStatusFunction: DefaultAPIFunction {
	
	override init() {
		super.init()
		requestType = .getBatteryStatus
		responseType = .getBatteryStatus
		
		DataModelManager.shared.set(value: 0, forKey: batteryChargeKey)
		DataModelManager.shared.set(value: BatteryStatus.charging,
		                            forKey: batteryStatusKey)
		DataModelManager.shared.set(value: 0, forKey: batteryVoltageKey)
		DataModelManager.shared.set(value: true, forKey: batteryPresentKey)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		return BatteryStatusUtility.body()
	}
	
}

struct BatteryStatusNotification: APINotification {
	var type: NotificationType {
		return .batteryStatus
	}
	
	var body: [String : Any] {
		return BatteryStatusUtility.body()
	}
}
