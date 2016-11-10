//
//  AdminRestricitions.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 10/11/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

class GetAdminRestriction: DefaultAPIFunction {

	override init() {
		super.init()
		requestType = .getAdminAccessRestrictions
		responseType = .getAdminAccessRestrictions
		
		for (_, value) in accessRestricitionKeys {
			DataModelManager.shared.set(value: true, forKey: value.enabledKey)
			DataModelManager.shared.set(value: "cioffi", forKey: value.passwordKey)
		}
		
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		var body: [String : Any] = [:]
		
		for (key, value) in accessRestricitionKeys {
			let value = DataModelManager.shared.get(forKey: value.enabledKey,
			                                        withDefault: true)
			
			body[key.description] = [
				"enabled": value
			]
		}
		return body
	}

}
