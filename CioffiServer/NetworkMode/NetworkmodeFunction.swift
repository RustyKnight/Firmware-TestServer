//
//  NetworkmodeFunction.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

class GetNetworkModeFunction: DefaultAPIFunction {
	
	override init() {
		super.init()
		requestType = .getNetworkMode
		responseType = .getNetworkMode
		DataModelManager.shared.set(value: NetworkMode.cellular,
		                            forKey: DataModelKeys.networkMode)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		var body: [String: [String: Any]] = [:]
		body["network"] = [
			"mode": DataModelManager.shared.get(forKey: DataModelKeys.networkMode,
			                                    withDefault: NetworkMode.cellular).rawValue
		]
		return body
	}
}

class SetNetworkModeFunction: DefaultAPIFunction {
	
	override init() {
		super.init()
		requestType = .setNetworkMode
		responseType = .setNetworkMode
		DataModelManager.shared.set(value: NetworkMode.cellular,
		                            forKey: DataModelKeys.networkMode)
	}
	
	override func preProcess(request: JSON) -> PreProcessResult {
		guard let modeValue = request["network"]["mode"].int else {
			log(warning: "Was expecting a network/mode, but didn't find one")
			return createResponse(type: .failed)
		}
		guard let mode = NetworkMode(rawValue: modeValue) else {
			log(warning: "\(modeValue) is not a valid NetworkMode")
			return createResponse(type: .failed)
		}
		DataModelManager.shared.set(value: mode,
		                            forKey: DataModelKeys.networkMode)
		return createResponse(type: .success)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		var body: [String: [String: Any]] = [:]
		body["network"] = [
			"mode": DataModelManager.shared.get(forKey: DataModelKeys.networkMode,
			                                    withDefault: NetworkMode.cellular).rawValue
		]
		return body
	}
	
}
