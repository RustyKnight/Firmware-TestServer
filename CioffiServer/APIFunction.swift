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

protocol SwitcherState {
    associatedtype StateType
    
    var state: StateType {get}
    var notification: APINotification? {get}
}

struct AnySwitcherState<T: RawRepresentable & Hashable>: SwitcherState where T.RawValue == Int {
    
    var state: T
    var notification: APINotification?
    
    init(state: T, notification: APINotification? = nil) {
        self.state = state
        self.notification = notification
    }
}

let modeSwitcherOperationQueue = OperationQueue()

class ModeSwitcher<T: RawRepresentable & Hashable> where T.RawValue == Int {
    let key: String
    let to: AnySwitcherState<T>
    let through: AnySwitcherState<T>
    let defaultMode: T
    
    var initialDelay = 1.0
    var switchDelay = 5.0
    
    init(key: String,
         to: AnySwitcherState<T>,
         through: AnySwitcherState<T>,
         defaultMode: T,
         initialDelay: TimeInterval = 1.0,
         switchDelay: TimeInterval = 5.0) {
        self.key = key
        self.to = to
        self.through = through
        self.defaultMode = defaultMode
        self.initialDelay = initialDelay
        self.switchDelay = switchDelay
    }
    
    func makeSwitch() {
        let startDelayOperation: Operation = DelayOperation(withDelay: initialDelay)
        let throughStateOperation: Operation = SetValueOperation<T>(withState: through, forKey: key, logState: { () in
            log(info: "Current State for \(self.key)= \(self.current)")
        })
        let switchDelayOperaiotn: Operation = DelayOperation(withDelay: switchDelay)
        let toStateOperation: Operation = SetValueOperation<T>(withState: to, forKey: key, logState: { () in
            log(info: "Current State for \(self.key)= \(self.current)")
        })
        
        throughStateOperation.addDependency(startDelayOperation)
        switchDelayOperaiotn.addDependency(throughStateOperation)
        toStateOperation.addDependency(switchDelayOperaiotn)

        modeSwitcherOperationQueue.addOperations([startDelayOperation, throughStateOperation, switchDelayOperaiotn, toStateOperation],
                                                 waitUntilFinished: false)
        
//        DataModelManager.shared.set(value: through,
//                                    forKey: key)
//        log(info: "Switch in \(initialDelay) seconds")
//        let time = DispatchTime.now() + initialDelay
//        DispatchQueue.global().asyncAfter(deadline: time) { 
////        DispatchQueue.global().after(when: .now() + initialDelay) {
//            log(info: "Switching to \(self.current)")
//            self.sendNotification()
//            log(info: "Switch in \(self.switchDelay) second")
//            let time = DispatchTime.now() + self.switchDelay
//            DispatchQueue.global().asyncAfter(deadline: time, execute: { 
//                DataModelManager.shared.set(value: self.to.rawValue,
//                                            forKey: self.key)
//                log(info: "Switched to \(self.current)")
//                self.sendNotification()
//            })
//        }
    }
    
    var current: T {
        return DataModelManager.shared.get(forKey: key,
                                           withDefault: defaultMode)
    }

}

class DelayOperation: Operation {
    
    let delay: TimeInterval
    
    init(withDelay delay: TimeInterval) {
        self.delay = delay
    }
    
    override func main() {
        super.main()
        log(info: "Sleep for \(delay) seconds")
        Thread.sleep(forTimeInterval: delay)
    }
}

typealias EmptyFunction = () -> Void

class SetValueOperation<T: RawRepresentable & Hashable>: Operation where T.RawValue == Int {

    let state: AnySwitcherState<T>
    let key: String
    let logState: EmptyFunction?
    
    init(withState state: AnySwitcherState<T>, forKey key: String, logState: EmptyFunction? = nil) {
        self.state = state
        self.key = key
        self.logState = logState
    }
    
    override func main() {
        super.main()
        log(info: "Switch \(key) to \(state.state)")
        DataModelManager.shared.set(value: state.state,
                                    forKey: key)
        if let logState = logState {
            logState()
        }
        sendNotification()
    }
    
    func sendNotification() {
        guard let notification = state.notification else {
            return
        }
        do {
            try Server.default.send(notification: notification)
        } catch let error {
            log(error: "\(error)")
        }
    }
}
