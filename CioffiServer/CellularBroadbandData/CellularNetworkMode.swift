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

let cellularNetworkModeKey = "CellularNetworkModeMode"

struct CellularNetworkModeUtilities {
	
	static func body() -> [String: Any] {
		let mode: CellularNetworkMode = DataModelManager.shared.get(forKey: cellularNetworkModeKey,
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
		                            forKey: cellularNetworkModeKey)
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
