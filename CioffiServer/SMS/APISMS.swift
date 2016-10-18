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
import PromiseKit

struct PendingMessage {
	let number: String
	let content: String
}

class SendSMS: DefaultAPIFunction {
	override init() {
		super.init()
		
		responseType = .sendSMS
		requestType = .sendSMS
	}
	
	override func preProcess(request: JSON) -> PreProcessResult {
		guard let number = request["message"]["number"].string else {
			return DefaultPreProcessResult.failed()
		}
		guard let message = request["message"]["content"].string else {
			return DefaultPreProcessResult.failed()
		}
		
		_ = firstly {
			return Promise<PendingMessage> { (fulfill, fail) in
				let delay = 0.1 + (Double(arc4random_uniform(60)) / 60.0)
				log(info: "Wait for \(delay * 60.0) seconds")
				DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: {
					fulfill(PendingMessage(number: number, content: message))
				})
			}.then(execute: { (message) -> Promise<Message> in
				return Promise<Message> {(fulfill, fail) in
					DispatchQueue.global().async {
						do {
							let newMessage = Message(date: Date(), text: message.content, status: .sending, read: false, direction: .outgoing)
							MessageManager.shared.add(newMessage, to: message.number)
							try Server.default.send(notification: NewMessageNotification(message: newMessage, number: message.number))
							fulfill(newMessage)
						} catch let error {
							fail(error)
						}
					}
				}
			}).then(execute: { (message) -> Promise<Message> in
				return Promise<Message> {(fulfill, fail) in
					let delay = 0.1 + (Double(arc4random_uniform(2 * 60)) / 60.0)
					log(info: "Wait for \(delay * 60.0) seconds")
					DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: {
						fulfill(message)
					})
				}
			}).then(execute: { (message) -> Void in
				let status = MessageStatus.random(from: [.sent, .failed])
				log(info: "Set status to \(status)")
				MessageManager.shared.update(message, status: status)
				log(info: "message.status == \(message.status)")
				try Server.default.send(notification: MessageStatusNotification(id: message.id,
				                                                                status: message.status))
			}).catch(execute: { (error) in
				log(error: "\(error)")
			})
		}
		
		return DefaultPreProcessResult.successful()
	}

	override func body(preProcessResult: Any?) -> [String : Any] {
		return [:]
	}
}

struct NewMessageNotification: APINotification {
	
	let message: Message
	let number: String
	
	var type: NotificationType {
		return .newSMS
	}
	
	var body: [String : Any] {
			return ["message": SMSUtilities.convert(message: message, number: number)]
	}
}

struct MessageStatusNotification: APINotification {
	
	let id: Int
	let status: MessageStatus
	
	var type: NotificationType {
		return .smsStatus
	}
	
	var body: [String : Any] {
		return ["update": ["msgid": id, "status": status.rawValue]]
	}
}

struct SMSUtilities {
	
	static var stupidDateFormat: DateFormatter {
		let df = DateFormatter()
		df.dateFormat = "yyyy-MM-dd HH:mm:ss"
		return df
	}
	
	static func convert(message: Message, number: String) -> [String: Any] {
				return [
					"id": message.id,
					"text": message.text,
					"number": number,
					"time": stupidDateFormat.string(from: message.date),
					"status": message.status.rawValue,
					"transport": SMSTransport.cellular.rawValue,
					"direction": message.direction.rawValue,
					"read": message.read
				]
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
				log(info: "[\(message.id)][\(conversation.number)][\(message.direction.rawValue)][\(message.date)] - \(message.text)")
				let thread = SMSUtilities.convert(message: message, number: conversation.number)
//				let thread: [String: Any] = [
//					"id": message.id,
//					"text": message.text,
//					"number": conversation.number,
//					"time": stupidDateFormat.string(from: message.date),
//					"status": message.status.rawValue,
//					"transport": SMSTransport.cellular.rawValue,
//					"direction": message.direction.rawValue,
//					"read": message.read
//				]
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
		guard let id = request["message"]["msgid"].int else {
			return createResponse(success: false)
		}
		MessageManager.shared.deleteMessagesBy(ids: [id])
		return createResponse(success: true, result: id)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		guard let result = preProcessResult as? Int else {
			return [:]
		}
		return ["message": ["msgid": result]]
	}
}
