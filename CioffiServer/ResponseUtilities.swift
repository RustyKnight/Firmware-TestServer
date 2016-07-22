//
//  File.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON

enum NotificationType: Int {
    case shutdownNotification = 3
    case networkRegistrationStatusNotification = 16
    case signalStrengthChangeNotification = 19
    case serviceProviderChangeNotification = 22
}


public enum ResponseType: Int {
    case unknown = -1
    case getVersion = 2
    case setNetworkMode = 6
    case getNetworkMode = 7
    case getAccessRestricitions = 9
    case unlockAdminAccessRestriction = 11
    case stopAdminAccess = 13
    case getNetworkRegistrationStatus = 15
    case getSignalStrength = 18
    case getServiceProviderName = 21
}

public enum ResponseCode: Int {
    case unknown = -1
    case success = 0
    case unsupportedAPIVersion = 1
    case unsupportedAPIType = 2
    case failure = 3
}

public class JSONResponseWrapper {
    var wrappedValue: JSON
    
    public var jsonValue: JSON {
        return wrappedValue
    }
    
    init(theValue: JSON) {
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
