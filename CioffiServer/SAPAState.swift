//
//  AutomaticSAPAState.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 2/09/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI



struct SAPAStatusUtility {
	static func automaticBody() -> [String: [String: Any]] {
		var body: [String: [String: Any]] = [:]
		let value: Bool = DataModelManager.shared.get(forKey: DataModelKeys.automaticSAPAState, withDefault: true)
		log(info: "\(DataModelKeys.automaticSAPAState) = \(value)")
		body["autosapa"] = [
			"active": value
		]
		return body
	}
	
	static func manualBody() -> [String: [String: Any]] {
		var body: [String: [String: Any]] = [:]
		let value: Bool = DataModelManager.shared.get(forKey: DataModelKeys.sapaState, withDefault: true)
		log(info: "\(DataModelKeys.sapaState) = \(value)")
		body["sapa"] = [
			"active": value
		]
		return body
	}
}

class GetAutomaticSAPAStatusFunction: DefaultAPIFunction {
	
	override init() {
		super.init()
		
		responseType = .getAutomaticSAPAStatus
		requestType = .getAutomaticSAPAStatus
		
		DataModelManager.shared.set(value: false, forKey: DataModelKeys.automaticSAPAState)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		return SAPAStatusUtility.automaticBody()
	}
	
}

class SetAutomaticSAPAStatusFunction: GetAutomaticSAPAStatusFunction {
	
	override init() {
		super.init()
		
		responseType = .setAutomaticSAPAStatus
		requestType = .setAutomaticSAPAStatus
	}
	
	override func preProcess(request: JSON) -> PreProcessResult {
		guard let state = request["autosapa"]["active"].bool else {
			log(warning: "Was expecting autosapa/active, but didn't find one")
			return createResponse(type: .failed)
		}
		DataModelManager.shared.set(value: state, forKey: DataModelKeys.automaticSAPAState)
		return createResponse(type: .success)
	}
	
}

class GetSAPAStatusFunction: DefaultAPIFunction {
	
	override init() {
		super.init()
		
		responseType = .getSAPAStatus
		requestType = .getSAPAStatus
		
		DataModelManager.shared.set(value: false, forKey: DataModelKeys.sapaState)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		return SAPAStatusUtility.manualBody()
	}
	
}

class StartStopSAPAFunction: GetSAPAStatusFunction {
	
	override init() {
		super.init()
		
		responseType = .startStopSAPA
		requestType = .startStopSAPA
	}
	
	override func preProcess(request: JSON) -> PreProcessResult {
		guard let state = request["sapa"]["active"].bool else {
			log(warning: "Was expecting autosapa/active, but didn't find one")
			return createResponse(type: .failed)
		}
		DataModelManager.shared.set(value: state, forKey: DataModelKeys.sapaState)
		return createResponse(type: .success)
	}
	
}

struct SAPAStatusNotification: APINotification {
	let type: NotificationType = NotificationType.sapaStatus
	
	var body: [String : Any] {
		return SAPAStatusUtility.manualBody()
	}
}
