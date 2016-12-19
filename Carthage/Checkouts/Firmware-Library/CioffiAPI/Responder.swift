//
//  File.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation

public protocol Responder {
	func sendUnsupportedAPIResponse(`for`: RequestType)
	func sendUnsupportedAPIResponse(`for`: Int)
	func send(response: ResponseCode, `for`: ResponseType, contents: [String: Any]?)
	func failed(request: RequestType, with type: ResponseCode)
	func failed(response: ResponseType, with type: ResponseCode)
//	func accessDenied(response: ResponseType, with type: ResponseCode)
	func succeeded(response: ResponseType, contents: [String: Any]?)
}
