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

	case getMissedCallCount = 104
	case clearMissedCallCount = 107

	case setOutboundFirewall = 109
	case getOutboundFirewall = 111

	case setInboundFirewall = 117
	case getInboundFirewall = 119

	case getIPAddressConfiguration = 115
	case setIPAddressConfiguration = 113

	case getQualityOfService = 127
	case setQualityOfService = 125

	case getDMZ = 135
	case setDMZ = 133

	case getPortForwardingConfiguration = 131
	case setPortForwardingConfiguration = 129

	case getMACAddressFilteringConfiguration = 123
	case setMACAddressFilteringConfiguration = 121

	case setEmergencyNumber = 93
	case getEmergencyNumber = 96

	case getCellularNetworkRoaming = 1000
	case setCellularNetworkRoaming = 1002

	case getCallStatus = 1004

	case getDataUsage = 1007

	case getSIMStatus = 1009
	case setSIMPIN = 1011
	case unlockSIM = 1013

	case getGNSSSetting = 1016
	case setGNSSSetting = 1018

	case getHardwareDiagnosticInfo = 1020

	case powerDown = 1022
	case reset = 1024

	case getPOSTResults = 80
	case getRealTimeResults = 82

	case getSystemAlerts = 1026

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
