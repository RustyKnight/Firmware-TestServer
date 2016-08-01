//
//  SatelliteServiceMode.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 28/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI
import SwiftyJSON

let satelliteServiceModeKey = "satelliteServiceMode.mode"

struct SatelliteServiceModeUtilities {
    static func body() -> [String : [String : AnyObject]] {
        var body: [String : [String : AnyObject]] = [:]
        guard let value = DataModelManager.shared.get(forKey: satelliteServiceModeKey,
                                                      withDefault: SatelliteServiceMode.voice.rawValue) as? Int else {
            return body
        }
        guard let mode = SatelliteServiceMode(rawValue: value) else {
            return body
        }
        
        body["service"] = [
            "mode": mode.rawValue
        ]
        
        return body
    }
}

class GetSatelliteServiceModeFunction: DefaultAPIFunction {
    
    override init() {
        super.init()
        requestType = .getSatelliteServiceMode
        responseType = .getSatelliteServiceMode
        DataModelManager.shared.set(value: SatelliteServiceMode.voice.rawValue,
                                    forKey: satelliteServiceModeKey)
    }
    
    override func body() -> [String : [String : AnyObject]] {
        return SatelliteServiceModeUtilities.body()
    }
    
}

class SetSatelliteServiceModeFunction: GetSatelliteServiceModeFunction {

    override init() {
        super.init()
        requestType = .setSatelliteServiceMode
        responseType = .setSatelliteServiceMode
    }

    override func preProcess(request: JSON) {
        guard let modeValue = request["service"]["mode"].int else {
            log(warning: "Was expecting a service/mode, but didn't find one")
            return
        }
        guard let mode = SatelliteServiceMode(rawValue: modeValue) else {
            log(warning: "Invalid satellite service mode value: \(modeValue)")
            return
        }
        guard mode == .voice || mode == .data else {
            log(warning: "Invalid satellite service mode, can only be voice of data: \(mode)")
            return
        }
        
        let switcher = ModeSwitcher(to: mode)
        switcher.makeSwitch()
    }
    
}

struct SatelliteServiceModeNotification: APINotification {
    var type: NotificationType {
        return .satelliteServiceModeChanged
    }
    
    
    var body: [String : [String : AnyObject]] {
        return SatelliteServiceModeUtilities.body()
    }
}

class ModeSwitcher {
    let to: SatelliteServiceMode
    let switchingMode: [SatelliteServiceMode: SatelliteServiceMode] = [
        .voice: .switchingToVoice,
        .data: .switchingToData,
    ]
    
    
    
    init(to: SatelliteServiceMode) {
        self.to = to
    }
    
    func makeSwitch() {
        guard let switchMode = switchingMode[to] else {
            log(error: "Bad to mode: \(to)")
            return
        }
        
        DataModelManager.shared.set(value: switchMode.rawValue,
                                    forKey: satelliteServiceModeKey)
        log(info: "Switch in one second")
        DispatchQueue.global().after(when: .now() + 1.0) {
            log(info: "Switching to \(self.current)")
            self.sendNotification()
            log(info: "Switch in ten second")
            DispatchQueue.global().after(when: .now() + 10.0) {
                DataModelManager.shared.set(value: self.to.rawValue,
                                            forKey: satelliteServiceModeKey)
                log(info: "Switch to \(self.current)")
                self.sendNotification()
            }
        }
    }
    
    var current: SatelliteServiceMode {
        guard let value = DataModelManager.shared.get(forKey: satelliteServiceModeKey, withDefault: SatelliteServiceMode.unknown.rawValue) as? Int else {
            return .unknown
        }
        guard let mode = SatelliteServiceMode(rawValue: value) else {
            return .unknown
        }
        return mode
    }
    
    func sendNotification() {
        do {
            try Server.default.send(notification: SatelliteServiceModeNotification())
        } catch let error {
            log(error: "\(error)")
        }
    }
}
