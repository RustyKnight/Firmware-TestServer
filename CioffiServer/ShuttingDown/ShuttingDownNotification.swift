//
//  ShuttingDownNotification.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI

enum SystemAlertType: Int {
    case powerButtonPressed = 0
    case criticalHighTemperature = 1
    case criticalLowTemperature = 2
    case batteryFlat = 3
}

struct SystemAlertNotification: APINotification {
    var type: NotificationType {
        return .systemAlerts
    }
    
    var body: [String : [String : Any]] {
        var data: [String : [String : Any]] = [:]
        data["alert"] = [
            "type": alertType.rawValue
        ]
        return data
    }
    
    let alertType: SystemAlertType
    
    init(type: SystemAlertType) {
        alertType = type
    }
}
