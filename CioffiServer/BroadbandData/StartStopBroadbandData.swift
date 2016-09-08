//
//  StartStopBroadbandData.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 8/09/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI
import SwiftyJSON

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
        DataModelManager.shared.set(value: CellularBroadbandDataStatus.inactive, forKey: cellularBroadbandDataActiveModeKey)
    }
    
    override func preProcess(request: JSON) {
        guard let state = request["broadband"]["active"].bool else {
            log(warning: "Missing broadband/active payload")
            return
        }
        
        switch ModemModule.current {
        case .satellite: switchSatellite(on: state)
        case .cellular: switchCellular(on: state)
        default: break
        }

    }
    
    func switchCellular(on: Bool) {
        DataModelManager.shared.set(value: on, forKey: cellularBroadbandDataActiveModeKey)
    }
    
    func switchSatellite(on: Bool) {
        if on {
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
        var active = false
        switch ModemModule.current {
        case .satellite:
            let mode = DataModelManager.shared.get(forKey: satelliteBroadbandDataActiveModeKey,
                                                   withDefault: SatelliteBroadbandDataStatus.dataInactive)
            active = mode != SatelliteBroadbandDataStatus.dataInactive
        case .cellular:
            let mode = DataModelManager.shared.get(forKey: cellularBroadbandDataActiveModeKey,
                                                   withDefault: false)
            active = mode
        default: break
        }
        body["broadband"] = [
            "active": active
        ]
        return body
    }

}
