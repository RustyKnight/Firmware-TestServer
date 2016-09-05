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
    
    static let majorVersionKey = "majorVersion"
    static let minorVersionKey = "minorVersion"
    static let patchVersionKey = "patchVersion"
    
    override init() {
        super.init()
        responseType = .getVersion
        requestType = .getVersion
        DataModelManager.shared.set(value: 1, forKey: GetVersionFunction.majorVersionKey)
        DataModelManager.shared.set(value: 1, forKey: GetVersionFunction.minorVersionKey)
        DataModelManager.shared.set(value: 1, forKey: GetVersionFunction.patchVersionKey)
    }
    
    override func body() -> [String : [String : Any]] {
        var body: [String: [String: Any]] = [:]
        body["firmware"] = [
            "majorVersion": DataModelManager.shared.get(forKey: GetVersionFunction.majorVersionKey, withDefault: 1),
            "minorVersion": DataModelManager.shared.get(forKey: GetVersionFunction.minorVersionKey, withDefault: 1),
            "patchVersion": DataModelManager.shared.get(forKey: GetVersionFunction.patchVersionKey, withDefault: 1),
        ]
        return body
    }

}
