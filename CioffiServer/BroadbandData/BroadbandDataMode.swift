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

class BroadbandDataModeStatusModeSwitcher: SimpleModeSwitcher<BroadbandDataModeStatus> {
	
	init(to: BroadbandDataModeStatus, through: BroadbandDataModeStatus) {
		super.init(key: DataModelKeys.broadbandDataActiveMode,
		           to: AnySwitcherState<BroadbandDataModeStatus>(state: to, notification: BroadbandDataModeStatusNotification()),
		           through: AnySwitcherState<BroadbandDataModeStatus>(state: through, notification: BroadbandDataModeStatusNotification()),
		           defaultMode: BroadbandDataModeStatus.unknown,
		           initialDelay: 0.0,
		           switchDelay:  5.0)
	}
	
}

struct BroadbandDataModeStatusUtilities {
	
	static func body() -> [String : Any] {
		let mode = DataModelManager.shared.get(forKey: DataModelKeys.broadbandDataActiveMode,
		                                       withDefault: BroadbandDataModeStatus.dataInactive)
		log(info: "\(DataModelKeys.broadbandDataActiveMode.key) = \(mode)")
		var uplinkSpeed: SatelliteBroadbandStreamingIPSpeed? = nil
		var downlinkSpeed: SatelliteBroadbandStreamingIPSpeed? = nil
		
		switch mode {
		case .activatingStreamingIP: fallthrough
		case .streamingIP:
			uplinkSpeed = DataModelManager.shared.get(forKey: DataModelKeys.satelliteBroadbandDataActiveUplinkSpeed, withDefault: SatelliteBroadbandStreamingIPSpeed.kbps16)
			downlinkSpeed = DataModelManager.shared.get(forKey: DataModelKeys.satelliteBroadbandDataActiveDownlinkSpeed, withDefault: SatelliteBroadbandStreamingIPSpeed.kbps16)
		default:
			break
		}
		
		var dataInfo: [String: Any] = [
			"mode": mode.rawValue
		]
		guard let uplink = uplinkSpeed, let downlink = downlinkSpeed else {
			let data: [String: Any] = ["broadband": dataInfo]
			return data
		}
		dataInfo["uplinkspeed"] = uplink.rawValue
		dataInfo["downlinkspeed"] = downlink.rawValue

		let data: [String: Any] = ["broadband": dataInfo]
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
		
		DataModelManager.shared.set(value: BroadbandDataModeStatus.dataInactive, forKey: DataModelKeys.broadbandDataActiveMode)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
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
		
		DataModelManager.shared.set(value: BroadbandDataModeStatus.dataInactive, forKey: DataModelKeys.broadbandDataActiveMode)
	}
	
	override func preProcess(request: JSON) -> PreProcessResult {
		guard let on = request["broadband"]["active"].bool else {
			log(warning: "Missing broadband/active payload")
			return createResponse(type: .failed)
		}
		
		if on {
			let settingsMode = DataModelManager.shared.get(forKey: DataModelKeys.satelliteBroadbandDataMode,
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
			
			let uplinkSpeed = DataModelManager.shared.get(forKey: DataModelKeys.satelliteBroadbandDataUplinkSpeed,
			                                              withDefault: SatelliteBroadbandStreamingIPSpeed.kbps16)
			let downlinkSpeed = DataModelManager.shared.get(forKey: DataModelKeys.satelliteBroadbandDataDownlinkSpeed,
			                                                withDefault: SatelliteBroadbandStreamingIPSpeed.kbps16)
			
			DataModelManager.shared.set(value: switchMode,
			                            forKey: DataModelKeys.broadbandDataActiveMode)
			DataModelManager.shared.set(value: uplinkSpeed,
			                            forKey: DataModelKeys.satelliteBroadbandDataActiveUplinkSpeed)
			DataModelManager.shared.set(value: downlinkSpeed,
			                            forKey: DataModelKeys.satelliteBroadbandDataActiveDownlinkSpeed)
			
      log(info: "\(DataModelKeys.broadbandDataActiveMode) = \(String(describing: DataModelManager.shared.get(forKey: DataModelKeys.broadbandDataActiveMode)))")
			
			let switcher = BroadbandDataModeStatusModeSwitcher(to: statusMode,
			                                                   through: switchMode)
			switcher.start()
		} else {
			let statusMode = DataModelManager.shared.get(forKey: DataModelKeys.broadbandDataActiveMode,
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
				switcher.start()
			} else {
				DataModelManager.shared.set(value: BroadbandDataModeStatus.dataInactive,
				                            forKey: DataModelKeys.broadbandDataActiveMode)
				do {
					try Server.default.send(notification: BroadbandDataModeStatusNotification())
				} catch let error {
					log(error: "\(error)")
				}
			}
		}
		return createResponse(type: .success)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		var body: [String: [String: Any]] = [:]
		let mode = DataModelManager.shared.get(forKey: DataModelKeys.broadbandDataActiveMode,
		                                       withDefault: BroadbandDataModeStatus.dataInactive)
		let active = mode != BroadbandDataModeStatus.dataInactive
		body["broadband"] = [
			"active": active
		]
		return body
	}
	
}
