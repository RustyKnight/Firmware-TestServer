//
//  DataModel.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation

protocol DataModel {
    func get(forKey: String) -> AnyObject?
    func get(forKey: String, withDefault: AnyObject) -> AnyObject
    func set(value: AnyObject, forKey: String)
}

struct DataModelManager {
    static let shared: DataModel = DefaultDataModel()
}

class DefaultDataModel: DataModel {
    var data: [String: AnyObject] = [:]
    
    func get(forKey: String) -> AnyObject? {
        return data[forKey]
    }
    
    func get(forKey: String, withDefault: AnyObject) -> AnyObject {
        guard let value = get(forKey: forKey) else {
            return withDefault
        }
        return value
    }
    
    func set(value: AnyObject, forKey: String) {
        data[forKey] = value
    }
}
