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
let broadbandDataActiveModeKey = "broadbandDataActiveMode" // What is the "active" mode
let broadbandDataActiveUplinkSpeedKey = "broadbandDataActiveUplinkSpeed" // What is the "active" speed
let broadbandDataActiveDownlinkSpeedKey = "broadbandDataActiveDownlinkSpeed" // What is the "active" speed

let broadbandDataModeKey = "broadbandDataMode"
let broadbandDataUplinkSpeedKey = "broadbandDataUplinkSpeed"
let broadbandDataDownlinkSpeedKey = "broadbandDataDownlinkSpeed"

class StartStopBroadbandDataMode: DefaultAPIFunction {
    override init() {
        super.init()
        
        responseType = .startStopBroadbandData
        requestType = .startStopBroadbandData
        
        DataModelManager.shared.set(value: BroadbandDataStatus.dataInactive, forKey: broadbandDataActiveModeKey)
    }
    
    override func preProcess(request: JSON) {
        guard let state = request["broadband"]["active"].bool else {
            log(warning: "Missing broadband/active payload")
            return
        }
        
        if state {
            let settingsMode = DataModelManager.shared.get(forKey: broadbandDataModeKey,
                                                           withDefault: BroadbandDataMode.standardIP)
            var statusMode: BroadbandDataStatus = .dataInactive
            var switchMode: BroadbandDataStatus = .dataInactive
            
            switch settingsMode {
            case .standardIP:
                statusMode = .standardIP
                switchMode = .activatingStandardIP
            case .streamingIP:
                statusMode = .streamingIP
                switchMode = .activatingStreamingIP
            }
            
            let uplinkSpeed = DataModelManager.shared.get(forKey: broadbandDataUplinkSpeedKey,
                                                          withDefault: BroadbandStreamingIPSpeed.kbps16)
            let downlinkSpeed = DataModelManager.shared.get(forKey: broadbandDataDownlinkSpeedKey,
                                                            withDefault: BroadbandStreamingIPSpeed.kbps16)
            
            DataModelManager.shared.set(value: switchMode,
                                        forKey: broadbandDataActiveModeKey)
            DataModelManager.shared.set(value: uplinkSpeed,
                                        forKey: broadbandDataActiveUplinkSpeedKey)
            DataModelManager.shared.set(value: downlinkSpeed,
                                        forKey: broadbandDataActiveDownlinkSpeedKey)
            
            let switcher = BroadbandStatusModeSwitcher(to: statusMode,
                                                       through: switchMode)
            switcher.makeSwitch()
        } else {
            let statusMode = DataModelManager.shared.get(forKey: broadbandDataActiveModeKey,
                                                         withDefault: BroadbandDataStatus.dataInactive)
            var switchMode: BroadbandDataStatus = .dataInactive
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
            
            if switchMode != BroadbandDataStatus.dataInactive {
                let switcher = BroadbandStatusModeSwitcher(to: BroadbandDataStatus.dataInactive,
                                                           through: switchMode)
                switcher.makeSwitch()
            } else {
                DataModelManager.shared.set(value: BroadbandDataStatus.dataInactive,
                                            forKey: broadbandDataActiveModeKey)
                do {
                    try Server.default.send(notification: BroadbandDataStatusNotification())
                } catch let error {
                    log(error: "\(error)")
                }
            }
        }
    }
    
    override func body() -> [String : [String : AnyObject]] {
        var body: [String: [String: AnyObject]] = [:]
        let mode = DataModelManager.shared.get(forKey: broadbandDataActiveModeKey,
                                               withDefault: BroadbandDataStatus.dataInactive)
        let active = mode != BroadbandDataStatus.dataInactive
        body["broadband"] = [
            "active": active
        ]
        return body
    }
    
}

private class BroadbandStatusModeSwitcher: ModeSwitcher<BroadbandDataStatus> {

    init(to: BroadbandDataStatus, through: BroadbandDataStatus) {
        super.init(key: broadbandDataActiveModeKey,
                   to: to,
                   through: through,
                   defaultMode: BroadbandDataStatus.dataInactive,
                   notification: BroadbandDataStatusNotification(),
                   initialDelay: 0.0,
                   switchDelay:  5.0)
    }

}


struct BroadbandDataStatusUtilities {
    
    static func bodyForCurrentStatus() -> [String : [String : AnyObject]] {
        let mode = DataModelManager.shared.get(forKey: broadbandDataActiveModeKey,
                                               withDefault: BroadbandDataStatus.dataInactive)
        return body(for: mode)
    }
    
    static func body(`for` mode: BroadbandDataStatus) -> [String : [String : AnyObject]]{
        var uplinkSpeed: BroadbandStreamingIPSpeed? = nil
        var downlinkSpeed: BroadbandStreamingIPSpeed? = nil
        
        switch mode {
        case .activatingStreamingIP: fallthrough
        case .streamingIP:
            uplinkSpeed = DataModelManager.shared.get(forKey: broadbandDataActiveUplinkSpeedKey, withDefault: BroadbandStreamingIPSpeed.kbps16)
            downlinkSpeed = DataModelManager.shared.get(forKey: broadbandDataActiveDownlinkSpeedKey, withDefault: BroadbandStreamingIPSpeed.kbps16)
        default:
            break
        }
        
        return body(for: mode, uplinkSpeed: uplinkSpeed, downlinkSpeed: downlinkSpeed)
    }
    
    static func body(`for` mode: BroadbandDataStatus,
                     uplinkSpeed: BroadbandStreamingIPSpeed? = nil,
                     downlinkSpeed: BroadbandStreamingIPSpeed? = nil) -> [String : [String : AnyObject]]{
        var data: [String : [String : AnyObject]] = [:]
        data["broadband"] = [
            "mode": mode.rawValue
        ]
        guard let uplinkSpeed = uplinkSpeed, let downlinkSpeed = downlinkSpeed else {
            return data
        }
        data["broadband"]?["uplinkspeed"] = uplinkSpeed.rawValue
        data["broadband"]?["downlinkspeed"] = downlinkSpeed.rawValue
        
        return data
    }
}

struct BroadbandDataStatusNotification: APINotification {
    let type: NotificationType = NotificationType.broadbandDataStatus
    
    var body: [String : [String : AnyObject]] {
        return BroadbandDataStatusUtilities.bodyForCurrentStatus()
    }
}


class GetBroadbandConnectionStatus: DefaultAPIFunction {
    override init() {
        super.init()
        
        responseType = .getBroadbandDataStatus
        requestType = .getBroadbandDataStatus
        
        DataModelManager.shared.set(value: BroadbandDataStatus.dataInactive, forKey: broadbandDataActiveModeKey)
   }
    
    override func body() -> [String : [String : AnyObject]] {
        return BroadbandDataStatusUtilities.bodyForCurrentStatus()
    }
}

struct BroadbandDataIPModeUtilities {
    static func body() -> [String : [String : AnyObject]] {
        var body: [String: [String: AnyObject]] = [:]
        body["broadband"] = [
            "mode": DataModelManager.shared.get(forKey: broadbandDataModeKey,
                                                withDefault: BroadbandDataMode.standardIP).rawValue
        ]
        return body
    }
}

class SetBroadbandDataIPMode: DefaultAPIFunction {
    override init() {
        super.init()
        requestType = .setBroadbandDataIPMode
        responseType = .setBroadbandDataIPMode
    }
    
    override func preProcess(request: JSON) {
        guard let mode = request["broadband"]["mode"].int else {
            log(warning: "Was expecting a broadband/mode, but didn't find one")
            return
        }
        DataModelManager.shared.set(value: mode,
                                    forKey: broadbandDataModeKey)
    }
    
    override func body() -> [String : [String : AnyObject]] {
        return BroadbandDataIPModeUtilities.body()
    }
}

class GetBroadbandDataIPMode: DefaultAPIFunction {
    
    override init() {
        super.init()
        requestType = .getBroadbandDataIPMode
        responseType = .getBroadbandDataIPMode
        DataModelManager.shared.set(value: BroadbandDataMode.standardIP,
                                    forKey: broadbandDataModeKey)
    }
    
    override func body() -> [String : [String : AnyObject]] {
        return BroadbandDataIPModeUtilities.body()
    }
}

struct BroadbandDataSpeedUtilities {
    static func body() -> [String : [String : AnyObject]] {
        var body: [String: [String: AnyObject]] = [:]
        body["broadband"] = [
            "uplinkspeed": DataModelManager.shared.get(forKey: broadbandDataUplinkSpeedKey,
                                                       withDefault: BroadbandStreamingIPSpeed.kbps16).rawValue,
            "downlinkspeed": DataModelManager.shared.get(forKey: broadbandDataDownlinkSpeedKey,
                                                         withDefault: BroadbandStreamingIPSpeed.kbps16).rawValue
        ]
        return body
    }
}

class SetBroadbandDataSpeed: DefaultAPIFunction {
    override init() {
        super.init()
        requestType = .setBroadbandStreamingSpeed
        responseType = .setBroadbandStreamingSpeed
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
                                    forKey: broadbandDataUplinkSpeedKey)
        DataModelManager.shared.set(value: downlink,
                                    forKey: broadbandDataDownlinkSpeedKey)
    }
    
    override func body() -> [String : [String : AnyObject]] {
        return BroadbandDataSpeedUtilities.body()
    }
}

class GetBroadbandDataSpeed: DefaultAPIFunction {
    
    override init() {
        super.init()
        requestType = .getBroadbandStreamingSpeed
        responseType = .getBroadbandStreamingSpeed
        DataModelManager.shared.set(value: BroadbandStreamingIPSpeed.kbps16,
                                    forKey: broadbandDataUplinkSpeedKey)
        DataModelManager.shared.set(value: BroadbandStreamingIPSpeed.kbps16,
                                    forKey: broadbandDataDownlinkSpeedKey)
    }
    
    override func body() -> [String : [String : AnyObject]] {
        return BroadbandDataSpeedUtilities.body()
    }
}

