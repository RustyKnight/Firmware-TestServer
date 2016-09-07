//
//  BroadbandData.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 9/08/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

// Represents the active mode status, which is seperate from the settings
let satelliteBroadbandDataActiveModeKey = "satelliteBroadbandDataActiveMode" // What is the "active" mode
let satelliteBroadbandDataActiveUplinkSpeedKey = "satelliteBroadbandDataActiveUplinkSpeed" // What is the "active" speed
let satelliteBroadbandDataActiveDownlinkSpeedKey = "satelliteBroadbandDataActiveDownlinkSpeed" // What is the "active" speed

let satelliteBroadbandDataModeKey = "satelliteBroadbandDataMode"
let satelliteBroadbandDataUplinkSpeedKey = "satelliteBroadbandDataUplinkSpeed"
let satelliteBroadbandDataDownlinkSpeedKey = "satelliteBroadbandDataDownlinkSpeed"

/*
 This needs to also deal with cellular mode, so we need to be able to determine which "network" is actually
 active :P
 */
class StartStopBroadbandDataMode: DefaultAPIFunction {
    override init() {
        super.init()
        
        responseType = .startStopBroadbandData
        requestType = .startStopBroadbandData
        
        DataModelManager.shared.set(value: SatelliteBroadbandDataStatus.dataInactive, forKey: satelliteBroadbandDataActiveModeKey)
    }
    
    override func preProcess(request: JSON) {
        guard let state = request["broadband"]["active"].bool else {
            log(warning: "Missing broadband/active payload")
            return
        }
        
        if state {
            let settingsMode = DataModelManager.shared.get(forKey: satelliteBroadbandDataModeKey,
                                                           withDefault: SatelliteBroadbandDataMode.standardIP)
            var statusMode: SatelliteBroadbandDataStatus = .dataInactive
            var switchMode: SatelliteBroadbandDataStatus = .dataInactive
            
            switch settingsMode {
            case .standardIP:
                statusMode = .standardIP
                switchMode = .activatingStandardIP
            case .streamingIP:
                statusMode = .streamingIP
                switchMode = .activatingStreamingIP
            }
            
            let uplinkSpeed = DataModelManager.shared.get(forKey: satelliteBroadbandDataUplinkSpeedKey,
                                                          withDefault: SatelliteBroadbandStreamingIPSpeed.kbps16)
            let downlinkSpeed = DataModelManager.shared.get(forKey: satelliteBroadbandDataDownlinkSpeedKey,
                                                            withDefault: SatelliteBroadbandStreamingIPSpeed.kbps16)
            
            DataModelManager.shared.set(value: switchMode,
                                        forKey: satelliteBroadbandDataActiveModeKey)
            DataModelManager.shared.set(value: uplinkSpeed,
                                        forKey: satelliteBroadbandDataActiveUplinkSpeedKey)
            DataModelManager.shared.set(value: downlinkSpeed,
                                        forKey: satelliteBroadbandDataActiveDownlinkSpeedKey)
            
            log(info: "\(satelliteBroadbandDataActiveModeKey) = \(DataModelManager.shared.get(forKey: satelliteBroadbandDataActiveModeKey))")
            
            let switcher = SatelliteBroadbandStatusModeSwitcher(to: statusMode,
                                                       through: switchMode)
            switcher.makeSwitch()
        } else {
            let statusMode = DataModelManager.shared.get(forKey: satelliteBroadbandDataActiveModeKey,
                                                         withDefault: SatelliteBroadbandDataStatus.dataInactive)
            var switchMode: SatelliteBroadbandDataStatus = .dataInactive
            switch statusMode {
            case .failedToActivateStandardIP: fallthrough
            case .failedToDeactivateStandardIP: fallthrough
            case .standardIP:
                switchMode = .deactivatingStandardIP
            case .failedToActivateStreamingIP: fallthrough
            case .failedToDeactivateStreamingIP: fallthrough
            case .streamingIP:
                switchMode = .deactivatingStreamingIP
            default: break
            }
            
            if switchMode != SatelliteBroadbandDataStatus.dataInactive {
                let switcher = SatelliteBroadbandStatusModeSwitcher(to: SatelliteBroadbandDataStatus.dataInactive,
                                                           through: switchMode)
                switcher.makeSwitch()
            } else {
                DataModelManager.shared.set(value: SatelliteBroadbandDataStatus.dataInactive,
                                            forKey: satelliteBroadbandDataActiveModeKey)
                do {
                    try Server.default.send(notification: SatelliteBroadbandDataStatusNotification())
                } catch let error {
                    log(error: "\(error)")
                }
            }
        }
    }
    
    override func body() -> [String : Any] {
        var body: [String: [String: Any]] = [:]
        let mode = DataModelManager.shared.get(forKey: satelliteBroadbandDataActiveModeKey,
                                               withDefault: SatelliteBroadbandDataStatus.dataInactive)
        let active = mode != SatelliteBroadbandDataStatus.dataInactive
        body["broadband"] = [
            "active": active
        ]
        return body
    }
    
}

private class SatelliteBroadbandStatusModeSwitcher: ModeSwitcher<SatelliteBroadbandDataStatus> {

    init(to: SatelliteBroadbandDataStatus, through: SatelliteBroadbandDataStatus) {
        super.init(key: satelliteBroadbandDataActiveModeKey,
                   to: AnySwitcherState<SatelliteBroadbandDataStatus>(state: to, notification: SatelliteBroadbandDataStatusNotification()),
                   through: AnySwitcherState<SatelliteBroadbandDataStatus>(state: through, notification: SatelliteBroadbandDataStatusNotification()),
                   defaultMode: SatelliteBroadbandDataStatus.dataInactive,
                   initialDelay: 0.0,
                   switchDelay:  5.0)
    }

}


struct SatelliteBroadbandDataStatusUtilities {
    
    static func bodyForCurrentStatus() -> [String : Any] {
        let mode = DataModelManager.shared.get(forKey: satelliteBroadbandDataActiveModeKey,
                                               withDefault: SatelliteBroadbandDataStatus.dataInactive)
        log(info: "\(satelliteBroadbandDataActiveModeKey) = \(mode)")
        return body(for: mode)
    }
    
    static func body(`for` mode: SatelliteBroadbandDataStatus) -> [String : Any]{
        var uplinkSpeed: SatelliteBroadbandStreamingIPSpeed? = nil
        var downlinkSpeed: SatelliteBroadbandStreamingIPSpeed? = nil
        
        switch mode {
        case .activatingStreamingIP: fallthrough
        case .streamingIP:
            uplinkSpeed = DataModelManager.shared.get(forKey: satelliteBroadbandDataActiveUplinkSpeedKey, withDefault: SatelliteBroadbandStreamingIPSpeed.kbps16)
            downlinkSpeed = DataModelManager.shared.get(forKey: satelliteBroadbandDataActiveDownlinkSpeedKey, withDefault: SatelliteBroadbandStreamingIPSpeed.kbps16)
        default:
            break
        }
        
        return body(for: mode, uplinkSpeed: uplinkSpeed, downlinkSpeed: downlinkSpeed)
    }
    
    static func body(`for` mode: SatelliteBroadbandDataStatus,
                     uplinkSpeed: SatelliteBroadbandStreamingIPSpeed? = nil,
                     downlinkSpeed: SatelliteBroadbandStreamingIPSpeed? = nil) -> [String : Any]{
        var data: [String : Any] = [:]
        data["broadband"] = [
            "mode": mode.rawValue
        ]
        guard let uplinkSpeed = uplinkSpeed, let downlinkSpeed = downlinkSpeed else {
            return data
        }
        data["broadband"] = ["uplinkspeed": uplinkSpeed.rawValue]
        data["broadband"] = ["downlinkspeed": downlinkSpeed.rawValue]
        
        return data
    }
}

struct SatelliteBroadbandDataStatusNotification: APINotification {
    let type: NotificationType = NotificationType.satelliteBroadbandData
    
    var body: [String : Any] {
        return SatelliteBroadbandDataStatusUtilities.bodyForCurrentStatus()
    }
}


class GetSatelliteBroadbandConnectionStatus: DefaultAPIFunction {
    override init() {
        super.init()
        
        responseType = .getSatelliteBroadbandDataStatus
        requestType = .getSatelliteBroadbandDataStatus
        
        DataModelManager.shared.set(value: SatelliteBroadbandDataStatus.dataInactive, forKey: satelliteBroadbandDataActiveModeKey)
   }
    
    override func body() -> [String : Any] {
        return SatelliteBroadbandDataStatusUtilities.bodyForCurrentStatus()
    }
}

struct SatelliteBroadbandDataIPModeUtilities {
    static func body() -> [String : Any] {
        var body: [String: [String: Any]] = [:]
        body["broadband"] = [
            "mode": DataModelManager.shared.get(forKey: satelliteBroadbandDataModeKey,
                                                withDefault: SatelliteBroadbandDataMode.standardIP).rawValue
        ]
        return body
    }
}

class SetSatelliteBroadbandDataIPMode: DefaultAPIFunction {
    override init() {
        super.init()
        requestType = .setSatelliteBroadbandDataIPMode
        responseType = .setSatelliteBroadbandDataIPMode
    }
    
    override func preProcess(request: JSON) {
        guard let mode = request["broadband"]["mode"].int else {
            log(warning: "Was expecting a broadband/mode, but didn't find one")
            return
        }
        DataModelManager.shared.set(value: mode,
                                    forKey: satelliteBroadbandDataModeKey)
    }
    
    override func body() -> [String : Any] {
        return SatelliteBroadbandDataIPModeUtilities.body()
    }
}

class GetSatelliteBroadbandDataIPMode: DefaultAPIFunction {
    
    override init() {
        super.init()
        requestType = .getSatelliteBroadbandDataIPMode
        responseType = .getSatelliteBroadbandDataIPMode
        DataModelManager.shared.set(value: SatelliteBroadbandDataMode.standardIP,
                                    forKey: satelliteBroadbandDataModeKey)
    }
    
    override func body() -> [String : Any] {
        return SatelliteBroadbandDataIPModeUtilities.body()
    }
}

struct SatelliteBroadbandDataSpeedUtilities {
    static func body() -> [String : Any] {
        var body: [String: [String: Any]] = [:]
        body["broadband"] = [
            "uplinkspeed": DataModelManager.shared.get(forKey: satelliteBroadbandDataUplinkSpeedKey,
                                                       withDefault: SatelliteBroadbandStreamingIPSpeed.kbps16).rawValue,
            "downlinkspeed": DataModelManager.shared.get(forKey: satelliteBroadbandDataDownlinkSpeedKey,
                                                         withDefault: SatelliteBroadbandStreamingIPSpeed.kbps16).rawValue
        ]
        return body
    }
}

class SetSatelliteBroadbandDataSpeed: DefaultAPIFunction {
    override init() {
        super.init()
        requestType = .setSatelliteBroadbandStreamingSpeed
        responseType = .setSatelliteBroadbandStreamingSpeed
    }
    
    override func preProcess(request: JSON) {
        guard let uplink = request["broadband"]["uplinkspeed"].int else {
            log(warning: "Was expecting a broadband/uplinkspeed, but didn't find one")
            return
        }
        guard let downlink = request["broadband"]["downlinkspeed"].int else {
            log(warning: "Was expecting a broadband/downlinkspeed, but didn't find one")
            return
        }
        DataModelManager.shared.set(value: uplink,
                                    forKey: satelliteBroadbandDataUplinkSpeedKey)
        DataModelManager.shared.set(value: downlink,
                                    forKey: satelliteBroadbandDataDownlinkSpeedKey)
    }
    
    override func body() -> [String : Any] {
        return SatelliteBroadbandDataSpeedUtilities.body()
    }
}

class GetSatelliteBroadbandDataSpeed: DefaultAPIFunction {
    
    override init() {
        super.init()
        requestType = .getSatelliteBroadbandStreamingSpeed
        responseType = .getSatelliteBroadbandStreamingSpeed
        DataModelManager.shared.set(value: SatelliteBroadbandStreamingIPSpeed.kbps16,
                                    forKey: satelliteBroadbandDataUplinkSpeedKey)
        DataModelManager.shared.set(value: SatelliteBroadbandStreamingIPSpeed.kbps16,
                                    forKey: satelliteBroadbandDataDownlinkSpeedKey)
    }
    
    override func body() -> [String : Any] {
        return SatelliteBroadbandDataSpeedUtilities.body()
    }
}

