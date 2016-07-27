//
//  GetVersionFunction.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

class GetVersionFunction: DefaultAPIFunction {
    
    override init() {
        super.init()
        responseType = .getVersion
        requestType = .getVersion
        DataModelManager.shared.set(value: 1, forKey: "majorVersion")
        DataModelManager.shared.set(value: 1, forKey: "minorVersion")
        DataModelManager.shared.set(value: 1, forKey: "patchVersion")
    }
    
    override func body() -> [String : [String : AnyObject]] {
        var body: [String: [String: AnyObject]] = [:]
        body["firmware"] = [
            "majorVersion": DataModelManager.shared.get(forKey: "majorVersion", withDefault: 1),
            "minorVersion": DataModelManager.shared.get(forKey: "minorVersion", withDefault: 1),
            "patchVersion": DataModelManager.shared.get(forKey: "patchVersion", withDefault: 1),
        ]
        return body
    }

}
