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

let networkRegistrationModuleKey = "networkRegistrationModule"
let networkRegistrationStatusKey = "networkRegistrationStatus"

struct GetNetworkRegistrationStatusFunctionUtilities {
    static func body() -> [String : [String : Any]] {
        var body: [String : [String : Any]] = [:]
        body["connection"] = [
            "module": DataModelManager.shared.get(forKey: networkRegistrationModuleKey,
                                                  withDefault: NetworkModule.satellite.rawValue)
        ]
        body["registration"] = [
            "status": DataModelManager.shared.get(forKey: networkRegistrationStatusKey,
                                                  withDefault: NetworkRegistrationStatus.registering.rawValue)
        ]
        return body
    }
}

class GetNetworkRegistrationStatusFunction: DefaultAPIFunction {
    
    override init() {
        super.init()
        requestType = .getNetworkRegistrationStatus
        responseType = .getNetworkRegistrationStatus
        
        DataModelManager.shared.set(value: NetworkModule.satellite.rawValue,
                                    forKey: networkRegistrationModuleKey)
        DataModelManager.shared.set(value: NetworkRegistrationStatus.registering.rawValue,
                                    forKey: networkRegistrationStatusKey)
    }
    
    override func body() -> [String : [String : Any]] {
        return GetNetworkRegistrationStatusFunctionUtilities.body()
    }
    
}

struct NetworkRegistrationStatusNotification: APINotification {
    var type: NotificationType {
        return .networkRegistrationStatusChanged
    }
    
    var body: [String : [String : Any]] {
        return GetNetworkRegistrationStatusFunctionUtilities.body()
    }
}
