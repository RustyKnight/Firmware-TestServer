//
//  ProtocolUtilities.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

extension ProtocolUtils {
	
	class func processRequest(header: Data, body: Data, `for` responder: Responder) throws {
		guard validCRC(fromHeader: header, body: body) else {
			throw ProtocolError.invalidCRC
		}
		guard let _ = String(data: body, encoding: String.Encoding.isoLatin1) else {
			throw ProtocolError.requestDecodingError
		}
		
		let json = JSON(data: body)
		log(info: "json: \(json)")
		RequestHandlerManager.default.handle(request: json, forResponder: responder)
	}
	
}
