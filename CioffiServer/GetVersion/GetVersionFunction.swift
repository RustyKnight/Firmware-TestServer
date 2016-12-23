//
//  GetVersionFunction.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

class GetVersionFunction: DefaultAPIFunction {
	
	override init() {
		super.init()
		responseType = .getVersion
		requestType = .getVersion
		DataModelManager.shared.set(value: 1, forKey: DataModelKeys.majorVersion)
		DataModelManager.shared.set(value: 0, forKey: DataModelKeys.minorVersion)
		DataModelManager.shared.set(value: 0, forKey: DataModelKeys.patchVersion)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		var body: [String: Any] = [:]
		body["firmware"] = [
			"majorVersion": DataModelManager.shared.get(forKey: DataModelKeys.majorVersion, withDefault: 1),
			"minorVersion": DataModelManager.shared.get(forKey: DataModelKeys.minorVersion, withDefault: 0),
			"patchVersion": DataModelManager.shared.get(forKey: DataModelKeys.patchVersion, withDefault: 0),
		]
		return body
	}
	
}
