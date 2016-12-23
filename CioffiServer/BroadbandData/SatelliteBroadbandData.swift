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


struct SatelliteBroadbandDataIPModeUtilities {
	static func body() -> [String : Any] {
		var body: [String: [String: Any]] = [:]
		body["broadband"] = [
			"mode": DataModelManager.shared.get(forKey: DataModelKeys.satelliteBroadbandDataMode,
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
		guard let modeValue = request["broadband"]["mode"].int else {
			log(warning: "Was expecting a broadband/mode, but didn't find one")
			return createResponse(type: .failed)
		}
		guard let mode = SatelliteBroadbandDataMode(rawValue: modeValue) else {
			return createResponse(type: .failed)
		}
		DataModelManager.shared.set(value: mode,
		                            forKey: DataModelKeys.satelliteBroadbandDataMode)
		return createResponse(type: .success)
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
		                            forKey: DataModelKeys.satelliteBroadbandDataMode)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		return SatelliteBroadbandDataIPModeUtilities.body()
	}
}

struct SatelliteBroadbandDataSpeedUtilities {
	static func body() -> [String : Any] {
		var body: [String: [String: Any]] = [:]
		body["broadband"] = [
			"uplinkspeed": DataModelManager.shared.get(forKey: DataModelKeys.satelliteBroadbandDataUplinkSpeed,
			                                           withDefault: SatelliteBroadbandStreamingIPSpeed.kbps16).rawValue,
			"downlinkspeed": DataModelManager.shared.get(forKey: DataModelKeys.satelliteBroadbandDataDownlinkSpeed,
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
			return createResponse(type: .failed)
		}
		guard let downlink = request["broadband"]["downlinkspeed"].int else {
			log(warning: "Was expecting a broadband/downlinkspeed, but didn't find one")
			return createResponse(type: .failed)
		}

		guard let uplinkSpeed = SatelliteBroadbandStreamingIPSpeed(rawValue: uplink) else {
			log(warning: "\(uplink) is not a valid speed value")
			return createResponse(type: .failed)
		}
		guard let downlinkSpeed = SatelliteBroadbandStreamingIPSpeed(rawValue: downlink) else {
			log(warning: "\(downlink) is not a valid speed value")
			return createResponse(type: .failed)
		}

		DataModelManager.shared.set(value: uplinkSpeed,
		                            forKey: DataModelKeys.satelliteBroadbandDataUplinkSpeed)
		DataModelManager.shared.set(value: downlinkSpeed,
		                            forKey: DataModelKeys.satelliteBroadbandDataDownlinkSpeed)
		return createResponse(type: .success)
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
		                            forKey: DataModelKeys.satelliteBroadbandDataUplinkSpeed)
		DataModelManager.shared.set(value: SatelliteBroadbandStreamingIPSpeed.kbps16,
		                            forKey: DataModelKeys.satelliteBroadbandDataDownlinkSpeed)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		return SatelliteBroadbandDataSpeedUtilities.body()
	}
}

