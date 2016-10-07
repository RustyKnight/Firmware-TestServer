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
	
	var stupidDateFormat: DateFormatter {
		let df = DateFormatter()
		df.dateFormat = "yyyy-MM-dd HH:mm:ss"
		return df
	}
	
	override init() {
		super.init()
		
		responseType = .getSMSList
		requestType = .getSMSList
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		var body: [String: Any] = [:]
		var messages: [Any] = []
		var totalLength = 0
		for conversation in MessageManager.shared.conversations {
			for message in conversation.messages {
				let direction = message.status.isIncoming ? 0 : 1
				log(info: "[\(message.id)][\(conversation.number)][\(direction)][\(message.date)] - \(message.text)")
				let thread: [String: Any] = [
					"id": message.id,
					"text": message.text,
					"number": conversation.number,
					"time": stupidDateFormat.string(from: message.date),
					"status": message.status.rawValue,
					"transport": SMSTransport.cellular.rawValue,
					"direction": direction
				]
				let len = length(of: thread)
				if len + totalLength < 65000 {
					messages.append(thread)
					totalLength += len
				}
			}
		}
		log(info: "Sending \(messages.count) messages")
		body["messages"] = messages
		return body
	}
	
	func length(of message: [String: Any]) -> Int {
		let json = JSON(message)
		guard let text = json.rawString(String.Encoding.isoLatin1, options: []) else {
			return 65000
		}
		return text.characters.count
	}
	
}

class DeleteSMS: DefaultAPIFunction {
	
	override init() {
		super.init()
		
		responseType = .deleteSMS
		requestType = .deleteSMS
	}
	
	override func preProcess(request: JSON) -> PreProcessResult {
		guard let id = request["message"]["msgid"].string else {
			return createResponse(success: false)
		}
		MessageManager.shared.deleteMessagesBy(ids: [id])
		return createResponse(success: true, result: id)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		guard let result = preProcessResult as? String else {
			return [:]
		}
		return ["message": ["msgid": result]]
	}
}
