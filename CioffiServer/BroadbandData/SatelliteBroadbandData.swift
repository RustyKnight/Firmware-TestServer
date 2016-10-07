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

// This deals with the settings

// Represents the active mode status, which is seperate from the settings
let satelliteBroadbandDataActiveUplinkSpeedKey = "satelliteBroadbandDataActiveUplinkSpeed" // What is the "active" speed
let satelliteBroadbandDataActiveDownlinkSpeedKey = "satelliteBroadbandDataActiveDownlinkSpeed" // What is the "active" speed

let satelliteBroadbandDataUplinkSpeedKey = "satelliteBroadbandDataUplinkSpeed"
let satelliteBroadbandDataDownlinkSpeedKey = "satelliteBroadbandDataDownlinkSpeed"

let satelliteBroadbandDataModeKey = "broadbandDataMode"

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
	
	override func preProcess(request: JSON) -> PreProcessResult {
		guard let mode = request["broadband"]["mode"].int else {
			log(warning: "Was expecting a broadband/mode, but didn't find one")
			return createResponse(success: false)
		}
		DataModelManager.shared.set(value: mode,
		                            forKey: satelliteBroadbandDataModeKey)
		return createResponse(success: true)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
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
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
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
	
	override func preProcess(request: JSON) -> PreProcessResult {
		guard let uplink = request["broadband"]["uplinkspeed"].int else {
			log(warning: "Was expecting a broadband/uplinkspeed, but didn't find one")
			return createResponse(success: false)
		}
		guard let downlink = request["broadband"]["downlinkspeed"].int else {
			log(warning: "Was expecting a broadband/downlinkspeed, but didn't find one")
			return createResponse(success: false)
		}
		DataModelManager.shared.set(value: uplink,
		                            forKey: satelliteBroadbandDataUplinkSpeedKey)
		DataModelManager.shared.set(value: downlink,
		                            forKey: satelliteBroadbandDataDownlinkSpeedKey)
		return createResponse(success: true)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
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
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		return SatelliteBroadbandDataSpeedUtilities.body()
	}
}

