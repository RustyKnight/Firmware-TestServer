//
//  RequestUtilities.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation

enum RequestType: Int {
    case unknown = -1
    case getVersion = 1
    case setNetworkMode = 4
    case getNetworkMode = 5
    case getAccessRestricitions = 8
    case unlockAdminAccessRestriction = 10
    case stopAdminAccess = 12
    case getNetworkRegistrationStatus = 14
    case getSignalStrength = 17
    case getServiceProviderName = 18
    
    static func `for`(_ value: Int) -> RequestType {
        guard let type = RequestType(rawValue: value) else {
            return RequestType.unknown
        }
        return type
    }
}
