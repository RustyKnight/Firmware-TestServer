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
	case shuttingDown = 3
	case networkRegistrationStatusChanged = 16
	case signalStrengthChanged = 19
	case serviceProviderChanged = 22
    case batteryStatusChanged = 25
    case satelliteServiceModeChanged = 30
    case broadbandDataStatus = 41
}


public enum ResponseType: Int {
	case unknown = -1
	case getVersion = 2
	case setNetworkMode = 6
	case getNetworkMode = 7
	case getAccessRestricitions = 9
	case unlockAccessRestriction = 11
	case stopAccess = 13
	case getNetworkRegistrationStatus = 15
	case getSignalStrength = 18
	case getServiceProviderName = 21
    case getBatteryStatus = 24
    case getSatelliteServiceMode = 27
    case setSatelliteServiceMode = 29
    
    case startStopBroadbandData = 38
    case getBroadbandDataStatus = 40
    case setBroadbandDataIPMode = 32
    case getBroadbandDataIPMode = 34
    case setBroadbandStreamingSpeed = 36
    case getBroadbandStreamingSpeed = 43
	
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
