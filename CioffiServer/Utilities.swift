//
//  Utilities.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 7/09/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI

func synced(lock: Any, closure: () -> ()) {
    defer {
        objc_sync_exit(lock)
    }
    objc_sync_enter(lock)
    closure()
}

let currentModemModuleKey = "currentModemModuleKey"

enum ModemModule: Int {
    case satellite = 0
    case cellular = 2
    case unknown = -1
    
    func makeCurrent() {
        DataModelManager.shared.set(value: self, forKey: currentModemModuleKey)
    }
    
    static func isCurrent(_ value: ModemModule?) -> Bool {
        guard let value = value else {
            return false
        }
        return value.isCurrent
    }
    
    var isCurrent: Bool {
        guard self != .unknown else {
            return false
        }
        let current = ModemModule.current
        guard current != .unknown else {
            return false
        }
        return current == self
    }
    
    static var current: ModemModule {
        let current = DataModelManager.shared.get(forKey: currentModemModuleKey, withDefault: ModemModule.unknown)
//        log(info: "current = \(current)")
        return current
    }
}

protocol ModemModular {
    var modemModule: ModemModule? {get set}
}
