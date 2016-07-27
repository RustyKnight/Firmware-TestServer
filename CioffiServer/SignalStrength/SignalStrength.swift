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
    static func body() -> [String : [String : AnyObject]] {
        var body: [String : [String : AnyObject]] = [:]
        guard let mode = DataModelManager.shared.get(forKey: "activeSignalStrength", withDefault: 0) as? Int else {
            return body
        }
        if mode == 0 {
            body["cellular"] = [
                "signal": DataModelManager.shared.get(forKey: "signalStrength", withDefault: 0)
            ]
        } else if mode == 1 {
            body["satellite"] = [
                "signal": DataModelManager.shared.get(forKey: "signalStrength", withDefault: 0)
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
        
        DataModelManager.shared.set(value: 0, forKey: "signalStrength")
        // Would be nice to get this from somewhere else
        DataModelManager.shared.set(value: 0, forKey: "activeSignalStrength")
    }
    
    override func body() -> [String : [String : AnyObject]] {
        return SignalStrengthUtility.body()
    }
    
}

struct SignalStrengthNotification: APINotification {
    var type: NotificationType {
        return .signalStrengthChanged
    }
    
    var body: [String : [String : AnyObject]] {
        return SignalStrengthUtility.body()
    }
}
