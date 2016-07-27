//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

struct BatteryStatusUtility {
    static func body() -> [String : [String : AnyObject]] {
        var body: [String : [String : AnyObject]] = [:]
        body["battery"] = [
            "charge": DataModelManager.shared.get(forKey: "batteryCharge", withDefault: 0),
            "status": DataModelManager.shared.get(forKey: "batteryStatus", withDefault: BatteryStatus.unknown.rawValue),
            "voltage": DataModelManager.shared.get(forKey: "batteryVoltage", withDefault: 0),
            "present": DataModelManager.shared.get(forKey: "batteryPresent", withDefault: true)
        ]
        return body
    }
}

class GetBatteryStatusFunction: DefaultAPIFunction {
    
    override init() {
        super.init()
        requestType = .getServiceProviderName
        responseType = .getServiceProviderName
        
        DataModelManager.shared.set(value: 0, forKey: "batteryCharge")
        DataModelManager.shared.set(value: BatteryStatus.charging.rawValue, forKey: "batteryStatus")
        DataModelManager.shared.set(value: 0, forKey: "batteryVoltage")
        DataModelManager.shared.set(value: true, forKey: "batteryPresent")
    }
    
    override func body() -> [String : [String : AnyObject]] {
        return BatteryStatusUtility.body()
    }
    
}

struct BatteryStatusNotification: APINotification {
    var type: NotificationType {
        return .batteryStatusChanged
    }
    
    var body: [String : [String : AnyObject]] {
        return BatteryStatusUtility.body()
    }
}
