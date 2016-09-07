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

let activeSignalStrengthKey = "activeSignalStrength"
let signalStrengthKey = "signalStrength"

struct SignalStrengthUtility {
    static func body() -> [String : Any] {
        var body: [String : Any] = [:]
        let mode = DataModelManager.shared.get(forKey: activeSignalStrengthKey, withDefault: SignalStrengthMode.satellite)
        if mode == SignalStrengthMode.cellular {
            body["cellular"] = [
                "signal": DataModelManager.shared.get(forKey: signalStrengthKey, withDefault: 0)
            ]
        } else if mode == SignalStrengthMode.satellite {
            body["satellite"] = [
                "signal": DataModelManager.shared.get(forKey: signalStrengthKey, withDefault: 0)
            ]
        }
        return body
    }
}

class GetSignalStrengthFunction: DefaultAPIFunction {
    
    override init() {
        super.init()
        requestType = .getSignalStrength
        responseType = .getSignalStrength
        
        DataModelManager.shared.set(value: 0, forKey: signalStrengthKey)
        // Would be nice to get this from somewhere else
        DataModelManager.shared.set(value: SignalStrengthMode.satellite, forKey: activeSignalStrengthKey)
    }
    
    override func body() -> [String : Any] {
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
