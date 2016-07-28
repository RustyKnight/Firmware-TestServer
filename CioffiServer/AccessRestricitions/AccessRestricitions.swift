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
    
    static let adminRestricitionKey = "adminRestricition"
    static let smsRestricitionKey = "smsRestricition"
    static let dataRestricitionKey = "dataRestricition"
    static let callRestricitionKey = "callRestricition"
    static let adminPasswordKey = "adminPassword"

    static let adminLockedKey = "adminLocked"
    static let smsLockedKey = "smsLocked"
    static let dataLockedKey = "dataLocked"
    static let callLockedKey = "callLocked"
    
    override init() {
        super.init()
        requestType = .getAccessRestricitions
        responseType = .getAccessRestricitions
        
        DataModelManager.shared.set(value: true, forKey: GetAccessRestricitionsFunction.adminRestricitionKey)
        DataModelManager.shared.set(value: true, forKey: GetAccessRestricitionsFunction.smsRestricitionKey)
        DataModelManager.shared.set(value: true, forKey: GetAccessRestricitionsFunction.dataRestricitionKey)
        DataModelManager.shared.set(value: true, forKey: GetAccessRestricitionsFunction.callRestricitionKey)
        
        DataModelManager.shared.set(value: true, forKey: GetAccessRestricitionsFunction.adminLockedKey)
        DataModelManager.shared.set(value: true, forKey: GetAccessRestricitionsFunction.smsLockedKey)
        DataModelManager.shared.set(value: true, forKey: GetAccessRestricitionsFunction.dataLockedKey)
        DataModelManager.shared.set(value: true, forKey: GetAccessRestricitionsFunction.callLockedKey)

        DataModelManager.shared.set(value: "cioffi", forKey: GetAccessRestricitionsFunction.adminPasswordKey)
    }
    
    override func body() -> [String : [String : AnyObject]] {
        var body: [String : [String : AnyObject]] = [:]
        body["admin"] = [
            "restricted": DataModelManager.shared.get(forKey: GetAccessRestricitionsFunction.adminRestricitionKey, withDefault: true)
        ]
        body["sms"] = [
            "restricted": DataModelManager.shared.get(forKey: GetAccessRestricitionsFunction.smsRestricitionKey, withDefault: true)
        ]
        body["data"] = [
            "restricted": DataModelManager.shared.get(forKey: GetAccessRestricitionsFunction.dataRestricitionKey, withDefault: true)
        ]
        body["call"] = [
            "restricted": DataModelManager.shared.get(forKey: GetAccessRestricitionsFunction.callRestricitionKey, withDefault: true)
        ]
        return body
    }
}

class UnlockAdminAccessRestricitionFunction: DefaultAPIFunction {

    override init() {
        super.init()
        requestType = .unlockAdminAccessRestriction
        responseType = .unlockAdminAccessRestriction
        
        DataModelManager.shared.set(value: true, forKey: GetAccessRestricitionsFunction.adminLockedKey)
        DataModelManager.shared.set(value: "cioffi", forKey: GetAccessRestricitionsFunction.adminPasswordKey)
    }
    
    var validated = false
    
    override func preProcess(request: JSON) {
        guard let password = request["login"]["password"].string else {
            validated = false
            return
        }
        guard let currentPassword = DataModelManager.shared.get(forKey: GetAccessRestricitionsFunction.adminPasswordKey,
                                                                withDefault: "cioffi") as? String else {
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
            DataModelManager.shared.set(value: false, forKey: GetAccessRestricitionsFunction.adminLockedKey)
            responder.succeeded(response: responseType, contents: body())
        } else {
            DataModelManager.shared.set(value: true, forKey: GetAccessRestricitionsFunction.adminLockedKey)
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
        DataModelManager.shared.set(value: true, forKey: GetAccessRestricitionsFunction.adminLockedKey)
    }
}
