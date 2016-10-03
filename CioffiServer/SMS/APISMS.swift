//
//  APISendSMS.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 23/09/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI
import SwiftyJSON

class SendSMS: DefaultAPIFunction {
	override init() {
		super.init()
		
		responseType = .sendSMS
		requestType = .sendSMS
	}
}

class GetSMSList: DefaultAPIFunction {
	
	override init() {
		super.init()
		
		responseType = .getSMSList
		requestType = .getSMSList
	}
	
	override func body() -> [String : Any] {
		var body: [String: Any] = [:]
		var messages: [Any] = []
		var totalLength = 0
		for conversation in MessageManager.shared.conversations {
			for message in conversation.messages {
				let thread: [Any] = [
					message.id,
					message.text,
					conversation.number,
					Int(message.date.timeIntervalSince1970 * 1000.0),
					message.status.rawValue,
					SMSTransport.cellular.rawValue
				]
				let len = length(of: thread)
				if len + totalLength < 65000 {
					messages.append(thread)
					totalLength += len
				}
			}
		}
		body["messages"] = messages
		return body
	}
	
	func length(of message: [Any]) -> Int {
		var body: [String: Any] = [:]
		body[""] = message
		let json = JSON(body)
		guard let text = json.rawString(String.Encoding.isoLatin1, options: []) else {
			return 65000
		}
		return text.characters.count
	}
	
}
