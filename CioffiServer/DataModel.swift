//
//  DataModel.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI

protocol DataModel {
    func get(forKey: String) -> AnyObject?
    func get(forKey: String, withDefault: AnyObject) -> AnyObject
    func set(value: AnyObject, forKey: String)
    func set(value: AnyObject, forKey: String, withNotification: Bool)
    func integer(forKey key: String, withDefault defaultValue: Int) -> Int
    func double(forKey key: String, withDefault defaultValue: Double) -> Double
    func bool(forKey key: String, withDefault defaultValue: Bool) -> Bool
    func string(forKey key: String, withDefault defaultValue: String) -> String
    
    func networkModule(forKey key: String, withDefault defaultValue: NetworkModule) -> NetworkModule
    
    func get<T: RawRepresentable where T.RawValue == Int>(forKey key: String, withDefault defaultValue: T) -> T
    func set<T: RawRepresentable where T.RawValue == Int>(value: T, forKey key: String)
    func set<T: RawRepresentable where T.RawValue == Int>(value: T, forKey key: String, withNotification: Bool)

    func get<R: AnyObject, T: RawRepresentable where T.RawValue == R>(forKey key: String, withDefault defaultValue: T) -> T
    func set<R: AnyObject, T: RawRepresentable where T.RawValue == R>(value: T, forKey key: String)
    func set<R: AnyObject, T: RawRepresentable where T.RawValue == R>(value: T, forKey key: String, withNotification: Bool)
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
    
    func get<T: RawRepresentable where T.RawValue == Int>(forKey key: String, withDefault defaultValue: T) -> T {
        guard let rawValue = get(forKey: key) as? Int else {
            return defaultValue
        }
        guard let value = T(rawValue: rawValue) else {
            return defaultValue
        }
        return value
    }

    func set<T: RawRepresentable where T.RawValue == Int>(value: T, forKey key: String) {
        set(value: value, forKey: key, withNotification: true)
    }

    func set<T: RawRepresentable where T.RawValue == Int>(value: T, forKey key: String, withNotification: Bool = true) {
        set(value: value.rawValue, forKey: key, withNotification: withNotification)
    }

    func set<R: AnyObject, T: RawRepresentable where T.RawValue == R>(value: T, forKey key: String) {
        set(value: value, forKey: key, withNotification: true)
    }
    
    func set<R: AnyObject, T: RawRepresentable where T.RawValue == R>(value: T, forKey key: String, withNotification: Bool = true) {
        set(value: value.rawValue, forKey: key, withNotification: withNotification)
    }
    
    func get<R: AnyObject, T: RawRepresentable where T.RawValue == R>(forKey key: String, withDefault defaultValue: T) -> T {
        guard let rawValue = get(forKey: key) as? R else {
            return defaultValue
        }
        guard let value = T(rawValue: rawValue) else {
            return defaultValue
        }
        return value
    }

    func set(value: AnyObject, forKey: String) {
        set(value: value, forKey: forKey, withNotification: true)
    }
    
    func set(value: AnyObject, forKey: String, withNotification: Bool = true) {
        data[forKey] = value
        if withNotification {
            NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: forKey),
                                            object: value)
        }
    }
    
    func integer(forKey key: String, withDefault defaultValue: Int) -> Int {
        guard let value = get(forKey: key, withDefault: defaultValue) as? Int else {
            return defaultValue
        }
        return value
    }
    
    func double(forKey key: String, withDefault defaultValue: Double) -> Double {
        guard let value = get(forKey: key, withDefault: defaultValue) as? Double else {
            return defaultValue
        }
        return value
    }
    
    func bool(forKey key: String, withDefault defaultValue: Bool) -> Bool {
        guard let value = get(forKey: key, withDefault: defaultValue) as? Bool else {
            return defaultValue
        }
        return value
    }
    
    func string(forKey key: String, withDefault defaultValue: String) -> String {
        guard let value = get(forKey: key, withDefault: defaultValue) as? String else {
            return defaultValue
        }
        return value
    }
    
    func networkModule(forKey key: String, withDefault defaultValue: NetworkModule) -> NetworkModule {
        guard let value = DataModelManager.shared.get(forKey: key, withDefault: defaultValue.rawValue) as? Int else {
            return defaultValue
        }
        guard let module = NetworkModule(rawValue: value) else {
            return defaultValue
        }
        return module
    }
}
