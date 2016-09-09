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

let broadbandDataActiveModeKey = "broadbandDataActiveMode" // What is the "active" mode

class BroadbandDataModeStatusModeSwitcher: ModeSwitcher<BroadbandDataModeStatus> {
	
	init(to: BroadbandDataModeStatus, through: BroadbandDataModeStatus) {
		super.init(key: broadbandDataActiveModeKey,
		           to: AnySwitcherState<BroadbandDataModeStatus>(state: to, notification: BroadbandDataModeStatusNotification()),
		           through: AnySwitcherState<BroadbandDataModeStatus>(state: through, notification: BroadbandDataModeStatusNotification()),
		           defaultMode: BroadbandDataModeStatus.unknown,
		           initialDelay: 0.0,
		           switchDelay:  5.0)
	}
	
}

struct BroadbandDataModeStatusUtilities {
	
	static func body() -> [String : Any] {
		let mode = DataModelManager.shared.get(forKey: broadbandDataActiveModeKey,
		                                       withDefault: BroadbandDataModeStatus.dataInactive)
		log(info: "\(broadbandDataActiveModeKey) = \(mode)")
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
		
		var data: [String : Any] = [:]
		data["broadband"] = [
			"mode": mode.rawValue
		]
		guard let uplink = uplinkSpeed, let downlink = downlinkSpeed else {
			return data
		}
		data["broadband"] = ["uplinkspeed": uplink.rawValue]
		data["broadband"] = ["downlinkspeed": downlink.rawValue]
		
		return data
	}
}


struct BroadbandDataModeStatusNotification: APINotification {
	let type: NotificationType = NotificationType.broadbandDataModeStatus
	
	var body: [String : Any] {
		return BroadbandDataModeStatusUtilities.body()
	}
}

class GetBroadbandDataModeStatus: DefaultAPIFunction {
	override init() {
		super.init()
		
		responseType = .getBroadbandDataModeStatus
		requestType = .getBroadbandDataModeStatus
		
		DataModelManager.shared.set(value: BroadbandDataModeStatus.dataInactive, forKey: broadbandDataActiveModeKey)
	}
	
	override func body() -> [String : Any] {
		return BroadbandDataModeStatusUtilities.body()
	}
}

/*
This needs to also deal with cellular mode, so we need to be able to determine which "network" is actually
active :P
*/
class StartStopBroadbandDataMode: DefaultAPIFunction {
	override init() {
		super.init()
		
		responseType = .startStopBroadbandData
		requestType = .startStopBroadbandData
		
		DataModelManager.shared.set(value: BroadbandDataModeStatus.dataInactive, forKey: broadbandDataActiveModeKey)
	}
	
	override func preProcess(request: JSON) {
		guard let on = request["broadband"]["active"].bool else {
			log(warning: "Missing broadband/active payload")
			return
		}
		
		if on {
			let settingsMode = DataModelManager.shared.get(forKey: satelliteBroadbandDataModeKey,
			                                               withDefault: SatelliteBroadbandDataMode.standardIP)
			var statusMode: BroadbandDataModeStatus = .dataInactive
			var switchMode: BroadbandDataModeStatus = .dataInactive
			
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
			                            forKey: broadbandDataActiveModeKey)
			DataModelManager.shared.set(value: uplinkSpeed,
			                            forKey: satelliteBroadbandDataActiveUplinkSpeedKey)
			DataModelManager.shared.set(value: downlinkSpeed,
			                            forKey: satelliteBroadbandDataActiveDownlinkSpeedKey)
			
			log(info: "\(broadbandDataActiveModeKey) = \(DataModelManager.shared.get(forKey: broadbandDataActiveModeKey))")
			
			let switcher = BroadbandDataModeStatusModeSwitcher(to: statusMode,
			                                                   through: switchMode)
			switcher.makeSwitch()
		} else {
			let statusMode = DataModelManager.shared.get(forKey: broadbandDataActiveModeKey,
			                                             withDefault: BroadbandDataModeStatus.dataInactive)
			var switchMode: BroadbandDataModeStatus = .dataInactive
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
			
			if switchMode != BroadbandDataModeStatus.dataInactive {
				let switcher = BroadbandDataModeStatusModeSwitcher(to: BroadbandDataModeStatus.dataInactive,
				                                                   through: switchMode)
				switcher.makeSwitch()
			} else {
				DataModelManager.shared.set(value: BroadbandDataModeStatus.dataInactive,
				                            forKey: broadbandDataActiveModeKey)
				do {
					try Server.default.send(notification: BroadbandDataModeStatusNotification())
				} catch let error {
					log(error: "\(error)")
				}
			}
		}
	}
	
	override func body() -> [String : Any] {
		var body: [String: [String: Any]] = [:]
		let mode = DataModelManager.shared.get(forKey: broadbandDataActiveModeKey,
		                                       withDefault: BroadbandDataModeStatus.dataInactive)
		let active = mode != BroadbandDataModeStatus.dataInactive
		body["broadband"] = [
			"active": active
		]
		return body
	}
	
}
