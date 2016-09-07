//
//  AutomaticSAPAState.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 2/09/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

let automaticSAPAState = "sapa.automaticState"

struct SapaStatusUtility {
    static func body() -> [String: [String: Any]] {
        var body: [String: [String: Any]] = [:]
        let value: Bool = DataModelManager.shared.get(forKey: automaticSAPAState, withDefault: true)
        log(info: "\(automaticSAPAState) = \(value)")
        body["autosapa"] = [
            "active": value
        ]
        return body
    }
}

class GetAutomaticSAPAStatusFunction: DefaultAPIFunction {
    
    override init() {
        super.init()
        
        responseType = .getAutomaticSAPAStatus
        requestType = .getAutomaticSAPAStatus
        
        DataModelManager.shared.set(value: false, forKey: automaticSAPAState)
    }
    
    override func body() -> [String : [String : Any]] {
        return SapaStatusUtility.body()
    }
    
}

class SetAutomaticSAPAStatusFunction: DefaultAPIFunction {
    
    override init() {
        super.init()
        
        responseType = .setAutomaticSAPAStatus
        requestType = .setAutomaticSAPAStatus
    }
    
    override func preProcess(request: JSON) {
        guard let state = request["autosapa"]["active"].bool else {
            log(warning: "Was expecting autosapa/active, but didn't find one")
            return
        }
        DataModelManager.shared.set(value: state, forKey: automaticSAPAState)
    }
    
    override func body() -> [String : [String : Any]] {
        return SapaStatusUtility.body()
    }
    
}
