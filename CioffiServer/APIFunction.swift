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

enum PreProcessResultType {
	case success
	case failed
	case accessDenied
}

protocol PreProcessResult {
	var type: PreProcessResultType {get}
	var result: Any? {get}
}

struct DefaultPreProcessResult: PreProcessResult {
	let type: PreProcessResultType
	let result: Any?
	
	static func successful(with: Any? = nil) -> DefaultPreProcessResult {
		return DefaultPreProcessResult(type: .success, result: with)
	}
	
	static func failed() -> DefaultPreProcessResult {
		return DefaultPreProcessResult(type: .failed, result: nil)
	}

	static func accessDenied() -> DefaultPreProcessResult {
		return DefaultPreProcessResult(type: .accessDenied, result: nil)
	}
}

class DefaultAPIFunction: APIFunction {
	
	var responseType: ResponseType = .unknown
	var requestType: RequestType = .unknown
	
	func body(preProcessResult: Any? = nil) -> [String: Any] {
		let body: [String: Any] = [:]
		return body
	}
	
	func createResponse(type: PreProcessResultType, result: Any? = nil) -> PreProcessResult {
		return DefaultPreProcessResult(type: type, result: result)
	}

	func preProcess(request: JSON) -> PreProcessResult {
		return createResponse(type: .success)
	}
	
	func postProcess(request: JSON) {
		
	}
	
	func handle(request: JSON, forResponder responder: Responder) throws {
		guard RequestType.from(request) == requestType else {
			throw APIFunctionError.invalidRequestType
		}
		
		let result = preProcess(request: request)
		switch result.type {
		case .success: responder.succeeded(response: responseType, contents: body(preProcessResult: result.result))
		case .failed: responder.failed(response: responseType, with: .failure)
		case .accessDenied: responder.failed(response: responseType, with: .accessDenied)
		}
//		if result.success {
//			responder.succeeded(response: responseType,
//			                    contents: body(preProcessResult: result.result))
//		} else {
//			responder.failed(response: responseType)
//		}
		postProcess(request: request)
	}
}

protocol ModeSwitcher {
	associatedtype ModeType: RawRepresentable

	var key: DataModelKey {get}
	var defaultMode: ModeType {get}
	
	var queue: OperationQueue {get}
	
	func start(completion: EmptyFunction?)
	func cancel()
}

extension ModeSwitcher {
	
	var current: ModeType {
		return DataModelManager.shared.get(forKey: key,
		                                   withDefault: defaultMode)
	}
	
	func logCurrentState() {
		log(info: "Current State for \(self.key)= \(self.current)")
	}

}

typealias EmptyFunction = () -> Void

protocol ModeLink {
	associatedtype ModeType: RawRepresentable
	
	var value: ModeType {get}
	var delay: TimeInterval {get}
	var notification: APINotification? {get}
}

struct AnyModeLink<T: RawRepresentable & Hashable>: ModeLink where T.RawValue == Int {// where T.RawValue == Int {
	typealias ModeType = T
	
	let value: T
	let delay: TimeInterval
	let notification: APINotification?
}

class LinkOperation<T: RawRepresentable & Hashable>: Operation where T.RawValue == Int {
	let modeLink: AnyModeLink<T>
	let key: DataModelKey
	let logState: EmptyFunction?
	
	init(key: DataModelKey, modeLink: AnyModeLink<T>, logState: EmptyFunction? = nil) {
		self.key = key
		self.modeLink = modeLink
		self.logState = logState
		super.init()
	}
	
	override func main() {
		super.main()
		
		let delay = modeLink.delay
		let value = modeLink.value
		
		log(info: "Sleep for \(delay) seconds")
		Thread.sleep(forTimeInterval: delay)
		
		log(info: "Switch \(key) to \(value)")
		DataModelManager.shared.set(value: value,
		                            forKey: key)
		if let logState = logState {
			logState()
		}
		sendNotification()
	}
	
	func sendNotification() {
		guard let notification = modeLink.notification else {
			return
		}
		do {
			try Server.default.send(notification: notification)
		} catch let error {
			log(error: "\(error)")
		}
	}
}
//
//class CompletionOperation: Operation {
//	let completion:
//	override func main() {
//		super.main()
//	}
//}

class ChainedModeSwitcher<T: RawRepresentable & Hashable>: ModeSwitcher where T.RawValue == Int {
	typealias ModeType = T
	
	let key: DataModelKey
	
	var initialDelay = 1.0
	var switchDelay = 5.0
	
	let defaultMode: T
	
	let links: [AnyModeLink<T>]
	
	var completion: EmptyFunction?
	
	lazy var queue: OperationQueue = {
		let queue = OperationQueue()
		queue.qualityOfService = QualityOfService.userInitiated
		return queue
	}()
	
	init(key: DataModelKey, defaultValue: T, links: [AnyModeLink<T>]) {
		self.key = key
		self.defaultMode = defaultValue
		self.links = links
	}
	
	func start(completion: EmptyFunction? = nil) {
		var operations: [LinkOperation<T>] = []
		var previousLink: LinkOperation<T>? = nil
		for link in links {
			let op = LinkOperation<T>(key: key, modeLink: link, logState: { () in
				log(info: "Current State for \(self.key)= \(self.current)")
			})
			operations.append(op)
			defer {
				previousLink = op
			}
			guard let previousLink = previousLink else {
				continue
			}
			op.addDependency(previousLink)
		}
		if let completion = completion, let previousLink = previousLink {
			previousLink.completionBlock = completion
		}
		
		queue.addOperations(operations, waitUntilFinished: false)
	}
	
	func cancel() {
		queue.cancelAllOperations()
		guard let completion = completion else {
			return
		}
		completion()
	}
	
	var current: T {
		return DataModelManager.shared.get(forKey: key,
		                                   withDefault: defaultMode)
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

class SimpleModeSwitcher<T: RawRepresentable & Hashable>: ChainedModeSwitcher<T> where T.RawValue == Int {
	
	init(key: DataModelKey,
	     to: AnySwitcherState<T>,
	     through: AnySwitcherState<T>,
	     defaultMode: T,
	     initialDelay: TimeInterval = 1.0,
	     switchDelay: TimeInterval = 5.0) {
		
		let fromLink = AnyModeLink(value: through.state, delay: initialDelay, notification: through.notification)
		let toLink = AnyModeLink(value: to.state, delay: switchDelay, notification: to.notification)
		
		super.init(key: key, defaultValue: defaultMode, links: [fromLink, toLink])
	}
	
	func link(from state: AnySwitcherState<T>, withDelay: TimeInterval) -> AnyModeLink<T> {
		return AnyModeLink(value: state.state, delay: withDelay, notification: state.notification)
	}
	
}
