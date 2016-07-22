//
//  RequestHandlerRegistry.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI

protocol RequestHandlerRegistry {
    func handler(`for`: RequestType) -> RequestHandler?
    func add(_ handler: RequestHandler, `for`: RequestType)
}

class RequestHandlerRegistryManager {
    static var `default`: RequestHandlerRegistry {
        return RequestHandlerRegistryFactory.registery
    }
}

class RequestHandlerRegistryFactory {
    static var registery: RequestHandlerRegistry = DefaultRequestHandlerRegistry()
}

class DefaultRequestHandlerRegistry: RequestHandlerRegistry {
    
    var registry: [RequestType: RequestHandler] = [:]
    
    init() {
        add(GetVersionHandler(), for: .getVersion)
    }
    
    func handler(for type: RequestType) -> RequestHandler? {
        return registry[type]
    }
    
    func add(_ handler: RequestHandler, `for` type: RequestType) {
        registry[type] = handler
    }
}
