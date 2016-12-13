//
//  RequestUtilities.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON

public enum RequestType: Int {
	case unknown = -1
	case getVersion = 1
	case setNetworkMode = 4
	case getNetworkMode = 5
	case getAccessRestricitions = 8
	case unlockAccessRestriction = 10
	case stopAccess = 12
	case getNetworkRegistrationStatus = 14
	case getSignalStrength = 17
	case getServiceProviderName = 20
	case getBatteryStatus = 23
	case getSatelliteServiceMode = 26
	case setSatelliteServiceMode = 28
	
	case startStopBroadbandData = 37
	case getBroadbandDataModeStatus = 39
	
	case setSatelliteBroadbandDataIPMode = 31
	case getSatelliteBroadbandDataIPMode = 33
	case setSatelliteBroadbandStreamingSpeed = 35
	case getSatelliteBroadbandStreamingSpeed = 42
	
	case getCellularNetworkMode = 44
	
	case getAutomaticSAPAStatus = 49
	case setAutomaticSAPAStatus = 47
	
	case startStopSAPA = 51
	case getSAPAStatus = 53
	
	case setWifiConfiguration = 56
	case getWifiConfiguration = 58
	
	case getSystemTemperature = 60
	
	case sendSMS = 63
	case getSMS = 65
	case getSMSList = 67
	case deleteSMS = 69
	case markSMS = 71
	
	case setAdminAccessRestrictions = 88
	case getAdminAccessRestrictions = 91

	case getCallLogs = 98
	case deleteCallLogs = 100
	case clearCallLogs = 102
	
	public static func `for`(_ value: Int) -> RequestType {
		guard let type = RequestType(rawValue: value) else {
			return RequestType.unknown
		}
		return type
	}
	
	public static func from(_ json: JSON) -> RequestType {
		guard let value = json["header"]["type"].int else {
			return RequestType.unknown
		}
		return RequestType.for(value)
	}
}
