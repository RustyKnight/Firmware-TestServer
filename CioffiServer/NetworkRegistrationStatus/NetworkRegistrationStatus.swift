//
//  NetworkRegistrationStatus.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

let satelliteNetworkRegistrationStatusKey = "satelliteRegistrationStatus"
let cellularNetworkRegistrationStatusKey = "cellularRegistrationStatus"

let modemModuleKeys: [ModemModule: String] = [
	.satellite: satelliteNetworkRegistrationStatusKey,
	.cellular: cellularNetworkRegistrationStatusKey
]

struct GetNetworkRegistrationStatusFunctionUtilities {
	static func body(`for` module: ModemModule? = nil) -> [String : Any] {
		var body: [String : Any] = [:]
		let reportModel = module != nil ? module! : ModemModule.current
		let moduleType = reportModel.rawValue
		
		let key = modemModuleKeys[reportModel]!
		body["connection"] = [
			"module": moduleType
		]
		body["registration"] = [
			"status": DataModelManager.shared.get(forKey: key,
			                                      withDefault: NetworkRegistrationStatus.registering).rawValue
		]
		return body
	}
}

class GetNetworkRegistrationStatusFunction: DefaultAPIFunction {
	
	override init() {
		super.init()
		requestType = .getNetworkRegistrationStatus
		responseType = .getNetworkRegistrationStatus
		
		DataModelManager.shared.set(value: NetworkRegistrationStatus.poweredOff,
		                            forKey: satelliteNetworkRegistrationStatusKey)
		DataModelManager.shared.set(value: NetworkRegistrationStatus.poweredOff,
		                            forKey: cellularNetworkRegistrationStatusKey)
	}
	
	override func body() -> [String : Any] {
		return GetNetworkRegistrationStatusFunctionUtilities.body()
	}
	
}

struct NetworkRegistrationStatusNotification: APINotification {

	let module: ModemModule?
	
	init(module: ModemModule? = nil) {
		self.module = module
	}
	
	var type: NotificationType {
		return .networkRegistrationStatus
	}
	
	var body: [String : Any] {
		return GetNetworkRegistrationStatusFunctionUtilities.body(for: module)
	}
}
