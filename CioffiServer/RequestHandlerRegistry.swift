//
//  RequestHandlerRegistry.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI
import SwiftyJSON
import Fuzi

enum RequestRegistryError: ErrorProtocol {
	case missingType
    case invalidType
    case missingName
    case missingRequest
    case missingResponse
    case missingHeaderType
    case missingHeaderVersion
    case missingGroupName
    case missingVariableName
    case missingVariableProperty
    case missingVariableType
    case missingVariableValue
    case missingAllowedValueName
    case missingAllowedValue
}

protocol RequestHandler {
	func handle(request: JSON, forResponder: Responder)
}

class RequestHandlerManager {
	static var `default`: RequestHandler {
		return RequestHandlerFactory.registery
	}
}

class RequestHandlerFactory {
	static var registery: RequestHandler = DefaultRequestHandler()
}

class DefaultRequestHandler: RequestHandler {
    
    var functions: [RequestType: APIFunction] = [:]
    
	init() {
        functions[.getVersion] = GetVersionFunction()
        functions[.getNetworkMode] = GetNetworkModeFunction()
        functions[.setNetworkMode] = SetNetworkModeFunction()
        
        functions[.getAccessRestricitions] = GetAccessRestricitionsFunction()
        functions[.unlockAdminAccessRestriction] = UnlockAdminAccessRestricitionFunction()
        functions[.stopAdminAccess] = StopAdminAccessFunction()
        
        functions[.getNetworkRegistrationStatus] = GetNetworkRegistrationStatusFunction()
        functions[.getSignalStrength] = GetSignalStrengthFunction()
        
        functions[.getBatteryStatus] = GetBatteryStatusFunction()
	}

    func handle(request: JSON, forResponder responder: Responder) {
		// Do we have a type
		guard let typeCode = request["header"]["type"].int else {
			return
		}
		// Look up the script
		let requestType = RequestType.for(typeCode)
		log(info: "requestType: \(requestType)")
        guard let function = functions[requestType] else {
            log(info: "No handler for request \(requestType)")
            responder.sendUnsupportedAPIResponse(for: requestType)
            return
        }
        do {
            try function.handle(request: request, forResponder: responder)
        } catch let error {
            log(error: "\(error)")
            responder.failed(request: requestType)
        }
	}
}

