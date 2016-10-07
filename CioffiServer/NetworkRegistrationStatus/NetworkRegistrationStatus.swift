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

let currentSatelliteNetworkRegistrationStatusKey = "NetworkRegistrationStatus.satellite.current"
let currentCellularNetworkRegistrationStatusKey = "NetworkRegistrationStatus.cellular.current"

let targetSatelliteNetworkRegistrationStatusKey = "NetworkRegistrationStatus.satellite.target"
let targetCellularNetworkRegistrationStatusKey = "NetworkRegistrationStatus.cellular.target"

let currentNetworkRegistrationStateKeys: [ModemModule: String] = [
	.satellite: currentSatelliteNetworkRegistrationStatusKey,
	.cellular: currentCellularNetworkRegistrationStatusKey
]

let targetNetworkRegistrationStateKeys: [ModemModule: String] = [
	.satellite: targetSatelliteNetworkRegistrationStatusKey,
	.cellular: targetCellularNetworkRegistrationStatusKey
]

struct GetNetworkRegistrationStatusFunctionUtilities {
	static func body(`for` module: ModemModule? = nil) -> [String : Any] {
		var body: [String : Any] = [:]
		let reportModel = module != nil ? module! : ModemModule.current
		let moduleType = reportModel.rawValue
		
		let key = currentNetworkRegistrationStateKeys[reportModel]!
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
		                            forKey: currentSatelliteNetworkRegistrationStatusKey)
		DataModelManager.shared.set(value: NetworkRegistrationStatus.registeredHomeNetwork,
		                            forKey: targetSatelliteNetworkRegistrationStatusKey)
		
		DataModelManager.shared.set(value: NetworkRegistrationStatus.poweredOff,
		                            forKey: currentCellularNetworkRegistrationStatusKey)
		DataModelManager.shared.set(value: NetworkRegistrationStatus.registeredHomeNetwork,
		                            forKey: targetCellularNetworkRegistrationStatusKey)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
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
