//
//  AccessRestricitions.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

class GetAccessRestricitionsFunction: DefaultAPIFunction {
    
    override init() {
        super.init()
        requestType = .getAccessRestricitions
        responseType = .getAccessRestricitions
        
        DataModelManager.shared.set(value: true, forKey: "adminRestricition")
        DataModelManager.shared.set(value: true, forKey: "smsRestricition")
        DataModelManager.shared.set(value: true, forKey: "dataRestricition")
        DataModelManager.shared.set(value: true, forKey: "callRestricition")
    }
    
    override func body() -> [String : [String : AnyObject]] {
        var body: [String : [String : AnyObject]] = [:]
        body["admin"] = [
            "restrcited": DataModelManager.shared.get(forKey: "adminRestricition", withDefault: true)
        ]
        body["sms"] = [
            "restrcited": DataModelManager.shared.get(forKey: "smsRestricition", withDefault: true)
        ]
        body["data"] = [
            "restrcited": DataModelManager.shared.get(forKey: "dataRestricition", withDefault: true)
        ]
        body["call"] = [
            "restrcited": DataModelManager.shared.get(forKey: "callRestricition", withDefault: true)
        ]
        return body
    }
}

class UnlockAdminAccessRestricitionFunction: DefaultAPIFunction {

    override init() {
        super.init()
        requestType = .unlockAdminAccessRestriction
        responseType = .unlockAdminAccessRestriction
        
        DataModelManager.shared.set(value: true, forKey: "adminRestricition")
        DataModelManager.shared.set(value: "cioffi", forKey: "adminPassword")
    }
    
    var validated = false
    
    override func preProcess(request: JSON) {
        guard let password = request["login"]["password"].string else {
            validated = false
            return
        }
        guard let currentPassword = DataModelManager.shared.get(forKey: "adminPassword", withDefault: "cioffi") as? String else {
            validated = false
            return
        }
        validated = password == currentPassword
    }
    
    override func handle(request: JSON, forResponder responder: Responder) throws {
        guard RequestType.from(request) == requestType else {
            throw APIFunctionError.invalidRequestType
        }
        
        preProcess(request: request)
        if validated {
            DataModelManager.shared.set(value: true, forKey: "adminRestricition")
            responder.succeeded(response: responseType, contents: body())
        } else {
            DataModelManager.shared.set(value: false, forKey: "adminRestricition")
            responder.accessDenied(response: responseType)
        }
    }
   
}

class StopAdminAccessFunction: DefaultAPIFunction {
    
    override init() {
        super.init()
        requestType = .stopAdminAccess
        responseType = .stopAdminAccess
    }
    
    override func preProcess(request: JSON) {
        DataModelManager.shared.set(value: false, forKey: "adminRestricition")
    }
}
