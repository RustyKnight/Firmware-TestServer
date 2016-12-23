//
//  CellularNetworkMode.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 7/9/16.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

struct CellularNetworkModeUtilities {
	
	static func body() -> [String: Any] {
		let mode: CellularNetworkMode = DataModelManager.shared.get(forKey: DataModelKeys.cellularNetworkMode,
		                                                            withDefault: CellularNetworkMode.cellular3G)
		return ["broadband": ["mode": mode.rawValue]]
	}
	
}

class GetCellularNetworkModeFunction: DefaultAPIFunction {
	
	override init() {
		super.init()
		responseType = .getCellularNetworkMode
		requestType = .getCellularNetworkMode
		
		DataModelManager.shared.set(value: CellularNetworkMode.cellular3G,
		                            forKey: DataModelKeys.cellularNetworkMode)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		return CellularNetworkModeUtilities.body()
	}
	
}

struct CellularNetworkModeNotification: APINotification {
	let type: NotificationType = NotificationType.cellularNetworkMode
	
	var body: [String : Any] {
		return CellularNetworkModeUtilities.body()
	}
}
