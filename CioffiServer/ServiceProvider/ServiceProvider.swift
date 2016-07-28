//
//  ServiceProvider.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

let activeServiceProviderKey = "activeServiceProvider"
let serviceProviderKey = "serviceProvider"

struct ServiceProviderUtility {
    static func body() -> [String : [String : AnyObject]] {
        var body: [String : [String : AnyObject]] = [:]
        let mode = DataModelManager.shared.networkModule(forKey: activeServiceProviderKey,
                                                         withDefault: NetworkModule.cellular)
        if mode == .cellular {
            body["cellular"] = [
                "provider": DataModelManager.shared.get(forKey: serviceProviderKey,
                                                      withDefault: 0)
            ]
        } else if mode == .satellite {
            body["satellite"] = [
                "provider": DataModelManager.shared.get(forKey: serviceProviderKey,
                                                      withDefault: 0)
            ]
        }
        return body
    }
}

class GetServiceProvideFunction: DefaultAPIFunction {
    
    override init() {
        super.init()
        requestType = .getServiceProviderName
        responseType = .getServiceProviderName
        
        DataModelManager.shared.set(value: "McDonalds",
                                    forKey: serviceProviderKey)
        // Would be nice to get this from somewhere else
        DataModelManager.shared.set(value: NetworkModule.cellular.rawValue,
                                    forKey: activeServiceProviderKey)
    }
    
    override func body() -> [String : [String : AnyObject]] {
        return ServiceProviderUtility.body()
    }
    
}

struct ServiceProviderNotification: APINotification {
    var type: NotificationType {
        return .serviceProviderChanged
    }
    
    var body: [String : [String : AnyObject]] {
        return ServiceProviderUtility.body()
    }
}
