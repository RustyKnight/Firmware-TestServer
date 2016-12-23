//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

struct BatteryStatusUtility {
	static func body() -> [String : Any] {
		var body: [String : Any] = [:]
		body["battery"] = [
			"charge": DataModelManager.shared.get(forKey: DataModelKeys.batteryCharge, withDefault: 0),
			"status": DataModelManager.shared.get(forKey: DataModelKeys.batteryStatus, withDefault: BatteryStatus.unknown).rawValue,
			"voltage": DataModelManager.shared.get(forKey: DataModelKeys.batteryVoltage, withDefault: 0),
			"present": DataModelManager.shared.get(forKey: DataModelKeys.batteryPresent, withDefault: true)
		]
		return body
	}
}

class GetBatteryStatusFunction: DefaultAPIFunction {
	
	override init() {
		super.init()
		requestType = .getBatteryStatus
		responseType = .getBatteryStatus
		
		DataModelManager.shared.set(value: 0, forKey: DataModelKeys.batteryCharge)
		DataModelManager.shared.set(value: BatteryStatus.charging,
		                            forKey: DataModelKeys.batteryStatus)
		DataModelManager.shared.set(value: 0, forKey: DataModelKeys.batteryVoltage)
		DataModelManager.shared.set(value: true, forKey: DataModelKeys.batteryPresent)
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
