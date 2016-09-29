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
	case sent = 1
	case read = 4
	case unread = 5
	
	static var random: MessageStatus {
		let states: [MessageStatus] = [.sent, .read, .unread]
		let index = Int(arc4random_uniform(UInt32(states.count)))
		return states[index]
	}
	
	var description: String {
		switch self {
		case .sent: return "Sent"
		case .read: return "Read"
		case .unread: return "Unread"
		}
	}
}

struct Conversation {
	let number: String
	let messages: [Message]
}

struct Message: CustomStringConvertible {
	let id: String = UUID().uuidString
	let date: Date
	let text: String
	let status: MessageStatus
	
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
				
				let text = messages[Int(index)]
				let element = Message(date: startDate!, text: text, status: MessageStatus.random)
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
