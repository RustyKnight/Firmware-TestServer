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

enum APIFunctionError: Error {
    case invalidRequestType
}

protocol APIFunction {
    func handle(request: JSON, forResponder responder: Responder) throws
}

class DefaultAPIFunction: APIFunction {
    
    var responseType: ResponseType = .unknown
    var requestType: RequestType = .unknown
    
    func body() -> [String: [String: Any]] {
        let body: [String: [String: Any]] = [:]
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

class ModeSwitcher<T: RawRepresentable & Hashable> where T.RawValue == Int {
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
         notification: APINotification,
         initialDelay: TimeInterval = 1.0,
         switchDelay: TimeInterval = 5.0) {
        self.key = key
        self.to = to
        self.through = through
        self.defaultMode = defaultMode
        self.notification = notification
        self.initialDelay = initialDelay
        self.switchDelay = switchDelay
    }
    
    func makeSwitch() {
        DataModelManager.shared.set(value: through,
                                    forKey: key)
        log(info: "Switch in \(initialDelay) seconds")
        let time = DispatchTime.now() + initialDelay
        DispatchQueue.global().asyncAfter(deadline: time) { 
//        DispatchQueue.global().after(when: .now() + initialDelay) {
            log(info: "Switching to \(self.current)")
            self.sendNotification()
            log(info: "Switch in \(self.switchDelay) second")
            let time = DispatchTime.now() + self.switchDelay
            DispatchQueue.global().asyncAfter(deadline: time, execute: { 
                DataModelManager.shared.set(value: self.to.rawValue,
                                            forKey: self.key)
                log(info: "Switched to \(self.current)")
                self.sendNotification()
            })
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
