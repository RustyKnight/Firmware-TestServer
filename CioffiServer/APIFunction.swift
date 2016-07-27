//
//  File.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

enum APIFunctionError: ErrorProtocol {
    case invalidRequestType
}

protocol APIFunction {
    func handle(request: JSON, forResponder responder: Responder) throws
}

class DefaultAPIFunction: APIFunction {
    
    var responseType: ResponseType = .unknown
    var requestType: RequestType = .unknown
    
    func body() -> [String: [String: AnyObject]] {
        let body: [String: [String: AnyObject]] = [:]
        return body
    }
    
    func preProcess(request: JSON) {
        
    }

    func postProcess(request: JSON) {
        
    }
    
    func handle(request: JSON, forResponder responder: Responder) throws {
        guard RequestType.from(request) == requestType else {
            throw APIFunctionError.invalidRequestType
        }
        
        preProcess(request: request)
        responder.succeeded(response: responseType, contents: body())
        postProcess(request: request)
    }
}
