//
// Created by Shane Whitehead on 14/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation

enum CallLogType: Int {
	case incomingAnswered = 0
	case outgoing
	case missed
}

func ==(lhs: CallLog, rhs: CallLog) -> Bool {
	return lhs.id == rhs.id
}

struct CallLog {
	let id: Int
	let type: CallLogType
	let number: String
	let time: String
	let duration: Int

	init(id: Int = IDGenerator.next, type: CallLogType, number: String, time: Date, duration: Int) {
		self.id = id
		self.type = type
		self.number = number
		self.time = stupidDateFormat.string(from: time)
		self.duration = duration
	}

	init(id: Int = IDGenerator.next, type: CallLogType, number: String, time: String, duration: Int) {
		self.id = id
		self.type = type
		self.number = number
		self.time = time
		self.duration = duration
	}

	func export() -> [String: Any] {
		return [
			"id": id,
			"type": type.rawValue,
			"number": number,
			"time": time,
			"duration": duration
		]
	}
}

class CallLogsManager {
	static let shared: CallLogsManager = CallLogsManager()

	var logs: [CallLog] = []

	private init() {
		refresh()
	}

	func refresh() {
		logs.append(CallLog(type: .incomingAnswered, number: "222", time: Date().adding(.second, value: -30), duration: 30))
		logs.append(CallLog(type: .outgoing, number: "999", time: Date().adding(.minute, value: -2), duration: 40))
		logs.append(CallLog(type: .missed, number: "55555", time: Date().adding(.hour, value: -1), duration: 50))
		logs.append(CallLog(type: .incomingAnswered, number: "0416060105", time: Date().adding(.hour, value: -1).adding(.minute, value: -15), duration: 60))
		logs.append(CallLog(type: .incomingAnswered, number: "+61416060105", time: Date().adding(.hour, value: -1).adding(.minute, value: -15), duration: 60))
//		logs.append(CallLog(type: .outgoing, number: "987654321", time: Date().adding(.day, value: -1).adding(.hour, value: 5).adding(.minute, value: -15), duration: 70))
//		logs.append(CallLog(type: .missed, number: "0907851236", time: Date().adding(.day, value: -2), duration: 80))
//		logs.append(CallLog(type: .incomingAnswered, number: "9191919191", time: Date().adding(.day, value: -2), duration: 90))
//		logs.append(CallLog(type: .outgoing, number: "134679085", time: Date().adding(.day, value: -3), duration: 100))
//		logs.append(CallLog(type: .missed, number: "197328465", time: Date().adding(.day, value: -3), duration: 110))
	}

	func clear() {
		logs.removeAll()
	}

	func remove(id: Int) {
		guard let index = (logs.index { $0.id == id }) else {
			return
		}
		logs.remove(at: index)
	}
}