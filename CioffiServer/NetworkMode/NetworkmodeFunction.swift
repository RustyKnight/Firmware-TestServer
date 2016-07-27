//
//  NetworkmodeFunction.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

class GetNetworkModeFunction: DefaultAPIFunction {
 
    override init() {
        super.init()
        requestType = .getNetworkMode
        responseType = .getNetworkMode
        DataModelManager.shared.set(value: NetworkMode.cellular.rawValue, forKey: "networkMode")
    }

    override func body() -> [String : [String : AnyObject]] {
        var body: [String: [String: AnyObject]] = [:]
        body["network"] = [
            "mode": DataModelManager.shared.get(forKey: "networkMode", withDefault: NetworkMode.cellular.rawValue)
        ]
        return body
    }
}

class SetNetworkModeFunction: DefaultAPIFunction {

    override init() {
        super.init()
        requestType = .setNetworkMode
        responseType = .setNetworkMode
        DataModelManager.shared.set(value: NetworkMode.cellular.rawValue, forKey: "networkMode")
    }
    
    override func preProcess(request: JSON) {
        guard let mode = request["network"]["mode"].int else {
            log(warning: "Was expecting a network/mode, but didn't find one")
            return
        }
        DataModelManager.shared.set(value: mode, forKey: "networkMode")
    }
    
    override func body() -> [String : [String : AnyObject]] {
        var body: [String: [String: AnyObject]] = [:]
        body["network"] = [
            "mode": DataModelManager.shared.get(forKey: "networkMode", withDefault: NetworkMode.cellular.rawValue)
        ]
        return body
    }
   
}
