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
let cellularBroadbandDataModeKey = "cellularBroadbandDataMode"

struct CellularBroadbandDataUtilities {
	
	static func bodyForCurrentStatus() -> [String: Any] {
        var mode: CellularBroadbandDataStatus = CellularBroadbandDataStatus.inactive
        if DataModelManager.shared.get(forKey: cellularBroadbandDataActiveModeKey, withDefault: false) {
            mode = DataModelManager.shared.get(forKey: cellularBroadbandDataModeKey,
                                               withDefault: CellularBroadbandDataStatus.cellular3G)
        }
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
		
		DataModelManager.shared.set(value: CellularBroadbandDataStatus.cellular3G,
		                            forKey: cellularBroadbandDataModeKey)
        DataModelManager.shared.set(value: false,
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
