//
//  NetworkRegistrationStatus.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

class GetNetworkRegistrationStatusFunction: DefaultAPIFunction {
    
    override init() {
        super.init()
        requestType = .getNetworkRegistrationStatus
        responseType = .getNetworkRegistrationStatus
        
        DataModelManager.shared.set(value: NetworkModule.satellite.rawValue, forKey: "networkRegistrationModule")
        DataModelManager.shared.set(value: NetworkRegistrationStatus.registering.rawValue, forKey: "networkRegistrationStatus")
    }
    
    override func body() -> [String : [String : AnyObject]] {
        var body: [String : [String : AnyObject]] = [:]
        body["connection"] = [
            "module": DataModelManager.shared.get(forKey: "networkRegistrationModule", withDefault: NetworkModule.satellite.rawValue)
        ]
        body["registration"] = [
            "status": DataModelManager.shared.get(forKey: "networkRegistrationStatus", withDefault: NetworkRegistrationStatus.registering.rawValue)
        ]
        return body
    }
    
}

struct NetworkRegistrationStatusNotification: APINotification {
    var type: NotificationType {
        return .networkRegistrationStatusChanged
    }
    
    var body: [String : [String : AnyObject]] {
        var body: [String : [String : AnyObject]] = [:]
        body["connection"] = [
            "module": DataModelManager.shared.get(forKey: "networkRegistrationModule", withDefault: NetworkModule.satellite.rawValue)
        ]
        body["registration"] = [
            "status": DataModelManager.shared.get(forKey: "networkRegistrationStatus", withDefault: NetworkRegistrationStatus.registering.rawValue)
        ]
        return body
    }
}
