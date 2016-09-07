//
//  CellularBroadbandData.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 7/9/16.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

let cellularBroadbandDataActiveModeKey = "cellularBroadbandDataActiveMode"

struct CellularBroadbandDataUtilities {
	
	static func bodyForCurrentStatus() -> [String: Any] {
		let mode = DataModelManager.shared.get(forKey: cellularBroadbandDataActiveModeKey,
		                                       withDefault: CellularBroadbandDataStatus.inactive)
		return body(for: mode)
	}
	
	static func body(`for` mode: CellularBroadbandDataStatus) -> [String: Any]{
		return ["broadband": ["mode": mode.rawValue]]
	}
	
}

class GetCellularBroadbandDataStatusFunction: DefaultAPIFunction {
	
	override init() {
		super.init()
		responseType = .getCellularBroadbandModeStatus
		requestType = .getCellularBroadbandModeStatus
		
		DataModelManager.shared.set(value: CellularBroadbandDataStatus.inactive,
		                            forKey: cellularBroadbandDataActiveModeKey)
	}
	
	override func body() -> [String : Any] {
		return CellularBroadbandDataUtilities.bodyForCurrentStatus()
	}
	
}

struct CellularBroadbandDataStatusNotification: APINotification {
	let type: NotificationType = NotificationType.cellularBroadbandData
	
	var body: [String : Any] {
		return CellularBroadbandDataUtilities.bodyForCurrentStatus()
	}
}
