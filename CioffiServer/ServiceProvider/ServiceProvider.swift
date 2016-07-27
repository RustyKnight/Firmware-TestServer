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

struct ServiceProviderUtility {
    static func body() -> [String : [String : AnyObject]] {
        var body: [String : [String : AnyObject]] = [:]
        guard let mode = DataModelManager.shared.get(forKey: "activeServiceProvider", withDefault: 0) as? Int else {
            return body
        }
        if mode == 0 {
            body["cellular"] = [
                "signal": DataModelManager.shared.get(forKey: "serviceProvider", withDefault: 0)
            ]
        } else if mode == 1 {
            body["satellite"] = [
                "signal": DataModelManager.shared.get(forKey: "serviceProvider", withDefault: 0)
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
        
        DataModelManager.shared.set(value: "McDonalds", forKey: "serviceProvider")
        // Would be nice to get this from somewhere else
        DataModelManager.shared.set(value: 0, forKey: "activeServiceProvider")
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
