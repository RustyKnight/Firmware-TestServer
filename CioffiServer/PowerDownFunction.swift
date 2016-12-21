//
// Created by Shane Whitehead on 19/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import PromiseKit
import CioffiAPI

class PowerDownFunction: DefaultAPIFunction {

	override init() {
		super.init()

		self.responseType = .powerDown
		self.requestType = .powerDown
	}

	override func body(preProcessResult: Any?) -> [String: Any] {
		_ = after(interval: 3.0).then { () -> Promise<Void> in
			self.send(notification: .powerButtonPressed)
			return after(interval: 3.0)
		}.then { () -> Promise<Void> in
			Server.default.stop()
			return after(interval: 3.0)
		}.then { () -> Void in
			try Server.default.start()
		}
		return [:]
	}

	func send(notification: SystemAlertType) {
		do {
			try Server.default.send(notification: SystemAlertNotification(type: notification))
		} catch let error {
			log(error: "\(error)")
		}
	}

}

class ResetFunction: PowerDownFunction {

	override init() {
		super.init()

		self.responseType = .reset
		self.requestType = .reset
	}

}
