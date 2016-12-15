//
//  File.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON

public enum NotificationType: Int {
	case systemAlerts = 3
	case networkRegistrationStatus = 16
	case signalStrength = 19
	case serviceProvider = 22
	case batteryStatus = 25
	case satelliteServiceMode = 30
	case broadbandDataModeStatus = 41
	case cellularNetworkMode = 46
	case sapaStatus = 55
	
	case systemTemperature = 62
	
	case newSMS = 73
	case smsStatus = 74
	
	case accessRestrictionChange = 90

	case missedCallCount = 106
}


public enum ResponseType: Int {
	case unknown = -1
	case getVersion = 2
	case setNetworkMode = 6
	case getNetworkMode = 7
	case getAccessRestrictions = 9
	case unlockAccessRestriction = 11
	case stopAccess = 13
	case getNetworkRegistrationStatus = 15
	case getSignalStrength = 18
	case getServiceProviderName = 21
	case getBatteryStatus = 24
	case getSatelliteServiceMode = 27
	case setSatelliteServiceMode = 29
	
	case startStopBroadbandData = 38
	case getBroadbandDataModeStatus = 40
	
	case setSatelliteBroadbandDataIPMode = 32
	case getSatelliteBroadbandDataIPMode = 34
	case setSatelliteBroadbandStreamingSpeed = 36
	case getSatelliteBroadbandStreamingSpeed = 43
	
	case getCellularNetworkMode = 45
	
	case setAutomaticSAPAStatus = 48
	case getAutomaticSAPAStatus = 50
	
	case startStopSAPA = 52
	case getSAPAStatus = 54
	
	case setWifiConfiguration = 57
	case getWifiConfiguration = 59

	case getSystemTemperature = 61
	
	case sendSMS = 64
	case getSMS = 66
	case getSMSList = 68
	case deleteSMS = 70
	case markSMS = 72

	case setAdminAccessRestrictions = 89
	case getAdminAccessRestrictions = 92

	case getCallLogs = 99
	case deleteCallLogs = 101
	case clearCallLogs = 103

	case getMissedCallCount = 105
	case clearMissedCallCount = 108

	case setOutboundFirewall = 110
	case getOutboundFirewall = 112

	case setInboundFirewall = 118
	case getInboundFirewall = 120

	case getIPAddressConfiguration = 116
	case setIPAddressConfiguration = 114

	public static func `for`(_ value: Int) -> ResponseType {
		guard let response = ResponseType(rawValue: value) else {
			return ResponseType.unknown
		}
		return response
	}
	
	public static func from(_ json: JSON) -> ResponseType {
		guard let value = json["header"]["type"].int else {
			return ResponseType.unknown
		}
		return ResponseType.for(value)
	}
}

public enum ResponseCode: Int {
	case unknown = -1
	case success = 0
	case unsupportedAPIVersion = 1
	case unsupportedAPIType = 2
	case failure = 3
	case accessDenied = 4
}

public class JSONResponseWrapper {
	var wrappedValue: JSON
	
	public var jsonValue: JSON {
		return wrappedValue
	}
	
	public init(theValue: JSON) {
		wrappedValue = theValue
	}
	
	internal var headerResult: Int {
		return wrappedValue["header"]["result"].intValue
	}
	
	internal var headerType: Int {
		return wrappedValue["header"]["type"].intValue
	}
	
	internal var headerVersion: Int {
		return wrappedValue["header"]["version"].intValue
	}
	
	public var responseCode: ResponseCode {
		guard let response = ResponseCode(rawValue: headerResult) else {
			return ResponseCode.unknown
		}
		return response
	}
	
	public var success: Bool {
		return responseCode == ResponseCode.success
	}
	
	public var responseType: ResponseType {
		guard let response = ResponseType(rawValue: headerType) else {
			return ResponseType.unknown
		}
		return response
	}
	
	public var version: Int {
		return headerVersion
	}
}
