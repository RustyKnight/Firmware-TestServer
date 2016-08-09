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

class ModeSwitcher<T: protocol<RawRepresentable, Hashable> where T.RawValue == Int> {
    let key: String
    let to: T
    let through: T
    let defaultMode: T
    let notification: APINotification
    
    var initialDelay = 1.0
    var switchDelay = 5.0
    
    init(key: String,
         to: T,
         through: T,
         defaultMode: T,
         notification: APINotification) {
        self.key = key
        self.to = to
        self.through = through
        self.defaultMode = defaultMode
        self.notification = notification
    }
    
    func makeSwitch() {
        DataModelManager.shared.set(value: through,
                                    forKey: key)
        log(info: "Switch in \(initialDelay) seconds")
        DispatchQueue.global().after(when: .now() + initialDelay) {
            log(info: "Switching to \(self.current)")
            self.sendNotification()
            log(info: "Switch in \(self.switchDelay) second")
            DispatchQueue.global().after(when: .now() + self.switchDelay) {
                DataModelManager.shared.set(value: self.to.rawValue,
                                            forKey: satelliteServiceModeKey)
                log(info: "Switch to \(self.current)")
                self.sendNotification()
            }
        }
    }
    
    var current: T {
        return DataModelManager.shared.get(forKey: key,
                                           withDefault: defaultMode)
    }
    
    func sendNotification() {
        do {
            try Server.default.send(notification: notification)
        } catch let error {
            log(error: "\(error)")
        }
    }

}
