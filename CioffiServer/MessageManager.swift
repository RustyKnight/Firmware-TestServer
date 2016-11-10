//
//  MessageManager.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 29/09/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI
import SwiftyJSON

enum MessageManagerError: Error {
	case missingMessages
	case missingNumbers
	case failedToLoadResource(named: String, withExtension: String)
}

enum MessageStatus: Int, CustomStringConvertible {
	case sending = 0
	case sent = 1
	case failed = 2
	case deleted = 3
	
	static var random: MessageStatus {
		let states: [MessageStatus] = [.sent, .failed, .deleted]
		return random(from: states)
	}
	
	static func random(from states: [MessageStatus]) -> MessageStatus {
		let index = Int(arc4random_uniform(UInt32(states.count)))
		return states[index]
	}
	
	var description: String {
		switch self {
		case .sending: return "Sending"
		case .sent: return "Sent"
		case .failed: return "Failed"
		case .deleted: return "Deleted"
		}
	}
}

enum MessageDirection: Int {
	case incoming = 1
	case outgoing = 0
	
	static var random: MessageDirection {
		let states: [MessageDirection] = [.incoming, .outgoing]
		let index = Int(arc4random_uniform(UInt32(states.count)))
		return states[index]
	}
}

class Conversation {
	let number: String
	var messages: [Message]
	
	init(number: String, messages: [Message]) {
		self.number = number
		self.messages = messages
	}
}

class IDGenerator {
	static internal var id: Int = 0
	static var next: Int {
		get {
			id += 1
			return id
		}
	}
}

class Message: CustomStringConvertible {
	let id: Int
	let date: Date
	let text: String
	var status: MessageStatus
	var read: Bool
	let direction: MessageDirection
	
	init(id: Int = IDGenerator.next, date: Date, text: String, status: MessageStatus, read: Bool, direction: MessageDirection) {
		self.id = id
		self.date = date
		self.text = text
		self.status = status
		self.read = read
		self.direction = direction
	}
	
	var description: String {
		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.timeStyle = .short
		
		return "[\(formatter.string(from: date)) \(status)]: \(text)"
	}
}

class MessageManager {
	static let shared: MessageManager = MessageManager()
	
	var messages: [String] = []
	var numbers: [String] = []
	
	var conversations: [Conversation] = []
	
	fileprivate init() {
		loadMessages()
		loadNumbers()
		
		generateConversations()
		
		add(Message(date: Date(), text: "😎", status: .sent, read: false, direction: .outgoing), to: "0416060105")
	}
	
	func add(_ message: Message, to number: String) {
		guard let conversation = (conversations.filter { (conversation) -> Bool in
			return conversation.number == number
		}).first else {
			return
		}
		
		conversation.messages.append(message)
	}
	
	func update(_ message: Message, status: MessageStatus) {
		for conversation in conversations {
			for checkMessage in conversation.messages {
				if checkMessage.id == message.id {
					log(info: "Update message (\(checkMessage.id))status to \(status)")
					checkMessage.status = status
					log(info: "checkMessage = \(checkMessage)")
				}
			}
		}
	}
	
	func deleteMessagesBy(ids: [Int]) {
		for conversation in conversations {
			let messages = conversation.messages.filter({ (message) -> Bool in
				return ids.index(of: message.id) == nil
			})
			conversation.messages = messages
			log(info: "Conversation has \(conversation.messages.count) left")
		}
		
		conversations = conversations.filter({ (conversation) -> Bool in
			return conversation.messages.count > 0
		})
	}
	
	func markMessage(id: Int, asRead read: Bool) -> Message? {
		var last: Message? = nil
		for conversation in conversations {
			let messages = conversation.messages.filter({ (message) -> Bool in
				return message.id == id
			})
			for message in messages {
				message.read = read
				last = message
			}
		}
		return last
	}
	
	func generateConversations() {
		for number in numbers {
			let count = arc4random_uniform(UInt32(messages.count))
			messages.shuffle()
			
//			log(info: "Number: \(number); with \(count) elements")
			var threads: [Message] = []
			let endDate = Date()
			var startDate = Calendar.current.date(byAdding:DateComponents(year: -1), to: endDate)
			
			for index in 0..<count {
				let interval = endDate.timeIntervalSince(startDate!)
				let randomInterval = TimeInterval((Double(arc4random()) / Double(UINT32_MAX)) * interval)

				startDate = startDate?.addingTimeInterval(randomInterval)
				
				let direction = MessageDirection.random
				var status = MessageStatus.random
				while direction == .incoming && status == .failed {
					status = MessageStatus.random
				}
				
				let text = messages[Int(index)]
				let element = Message(date: startDate!,
				                      text: text,
				                      status: status,
				                      read: true,
				                      direction: MessageDirection.random)
//				log(info: "\(index): \(element)")
				threads.append(element)
			}
			
			conversations.append(Conversation(number: number, messages: threads))
		}
	}
	
	func loadMessages() {
		do {
			let json = try loadResource(named: "Messages", ofType: "json")
			guard let messages = json["messages"].arrayObject else {
				throw MessageManagerError.missingMessages
			}
			
			self.messages = process(messages)
		} catch let error {
			log(error: "Failed to load messages: \(error)")
		}
	}
	
	func loadNumbers() {
		do {
			let json = try loadResource(named: "PhoneNumbers", ofType: "json")
			guard let phoneNumbers = json["numbers"].arrayObject else {
				throw MessageManagerError.missingNumbers
			}
			
			numbers = process(phoneNumbers)
		} catch let error {
			log(error: "Failed to load messages: \(error)")
		}
	}
	
	func process(_ values: [Any]) -> [String] {
		var results: [String] = []
		for message in values {
			guard let value = message as? String else {
				log(warning: "Not a valid number: \(message)")
				continue
			}
			results.append(value)
		}
		return results
	}
	
	func loadResource(named: String, ofType type: String) throws -> JSON {
		guard let url = Bundle.main.url(forResource: named, withExtension: type) else {
			log(error: "Failed to find resource: \(named).\(type)")
			throw MessageManagerError.failedToLoadResource(named: named, withExtension: type)
		}
		let data = try Data(contentsOf: url)
		let json = JSON(data: data)
		
		return json
	}
}

extension MutableCollection where Indices.Iterator.Element == Index {
	/// Shuffles the contents of this collection.
	mutating func shuffle() {
		let c = count
		guard c > 1 else { return }
		
		for (unshuffledCount, firstUnshuffled) in zip(stride(from: c, to: 1, by: -1), indices) {
			let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
			guard d != 0 else { continue }
			let i = index(firstUnshuffled, offsetBy: d)
			swap(&self[firstUnshuffled], &self[i])
		}
	}
}

extension Sequence {
	/// Returns an array with the contents of this sequence, shuffled.
	func shuffled() -> [Iterator.Element] {
		var result = Array(self)
		result.shuffle()
		return result
	}
}
