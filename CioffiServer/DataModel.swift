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
    func get(forKey: String) -> Any?
//    func get(forKey: String, withDefault: Any) -> Any
    func set(value: Any, forKey: String)
    func set(value: Any, forKey: String, withNotification: Bool)
//    func integer(forKey key: String, withDefault defaultValue: Int) -> Int
//    func double(forKey key: String, withDefault defaultValue: Double) -> Double
//    func bool(forKey key: String, withDefault defaultValue: Bool) -> Bool
//    func string(forKey key: String, withDefault defaultValue: String) -> String
    
//    func networkModule(forKey key: String, withDefault defaultValue: NetworkModule) -> NetworkModule
    
//    func get<T: RawRepresentable>(forKey key: String, withDefault defaultValue: T) -> T where T.RawValue == Int
//    func set<T: RawRepresentable>(value: T, forKey key: String) where T.RawValue == Int
//    func set<T: RawRepresentable>(value: T, forKey key: String, withNotification: Bool) where T.RawValue == Int
//
//    func get<R: Any, T: RawRepresentable>(forKey key: String, withDefault defaultValue: T) -> T where T.RawValue == R
//    func set<R: Any, T: RawRepresentable>(value: T, forKey key: String) where T.RawValue == R
//    func set<R: Any, T: RawRepresentable>(value: T, forKey key: String, withNotification: Bool) where T.RawValue == R
    
    func get<R: Any>(forKey key: String, withDefault defaultValue: R) -> R
}

struct DataModelManager {
    static let shared: DataModel = DefaultDataModel()
}

class DefaultDataModel: DataModel {
    var data: [String: Any] = [:]
    
    func get<R : Any>(forKey key: String, withDefault defaultValue: R) -> R {
        guard let value = get(forKey: key) as? R else {
            return defaultValue
        }
        return value
    }
    
    func get(forKey: String) -> Any? {
        var value: Any? = nil
        synced(lock: self) {
            value = self.data[forKey]
//            log(info: "Get \(forKey) is \(value)")
        }
        return value
    }

    func set(value: Any, forKey: String) {
        set(value: value, forKey: forKey, withNotification: true)
    }
    
    func set(value: Any, forKey: String, withNotification: Bool = true) {
        synced(lock: self) {
//            log(info: "Set \(forKey) to \(value)")
            data[forKey] = value
            if withNotification {
                NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: forKey),
                                                object: value)
            }
        }
    }
}
