//
//  ShuttingDownNotification.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI

enum ShuttingDownReason: Int {
    case powerButtonPressed = 0
    case criticalHighTemperature = 1
    case criticalLowTemperature = 2
    case batteryFlat = 3
}

struct ShuttingDownNotification: APINotification {
    var type: NotificationType {
        return .shuttingDown
    }
    
    var payload: [String : [String : AnyObject]] {
        var data: [String : [String : AnyObject]] = [:]
        data["alert"] = [
            "type": alertType.rawValue
        ]
        return data
    }
    
    let alertType: ShuttingDownReason
    
    init(type: ShuttingDownReason) {
        alertType = type
    }
}
