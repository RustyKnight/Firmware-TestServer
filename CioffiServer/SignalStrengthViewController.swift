//
//  SignalStrengthViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 28/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class SignalStrengthViewController: NSViewController, ModemModular {
	
	@IBOutlet weak var signalStrengthSegment: NSSegmentedControl!
	@IBOutlet weak var liveUpdate: NSButton!
	@IBOutlet weak var notificationButton: NSButton!
	
	var modemModule: ModemModule? {
		didSet {
			modemChanged()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		modemChanged()
		updateStrength()
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(modemChanged),
		                                       name: DataModelKeys.currentModemModule.notification,
		                                       object: nil)
	}
	
	override func viewDidDisappear() {
		super.viewDidDisappear()
		NotificationCenter.default.removeObserver(self)
	}
	
	@objc func modemChanged() {
		DispatchQueue.main.async {
			if self.liveUpdate != nil {
				self.liveUpdate.isEnabled = ModemModule.isCurrent(self.modemModule)
				self.notificationButton.isEnabled = ModemModule.isCurrent(self.modemModule)
			}
		}
	}
	
	@IBAction func signalStrengthValueChanged(_ sender: NSObject) {
		let strength = signalStrengthSegment.selectedSegment
		DataModelManager.shared.set(value: strength,
		                            forKey: DataModelKeys.signalStrength,
		                            withNotification: false)
		liveNotification()
	}
	
	@IBAction func sendNotification(_ sender: NSButton) {
		if ModemModule.isCurrent(self.modemModule) {
			do {
				try Server.default.send(notification: SignalStrengthNotification())
			} catch let error {
				log(error: "\(error)")
			}
		}
	}
	
	func liveNotification() {
		if liveUpdate.state == NSControl.StateValue.on && ModemModule.isCurrent(modemModule) {
			do {
				try Server.default.send(notification: SignalStrengthNotification())
			} catch let error {
				log(error: "\(error)")
			}
		}
	}
	
	func updateStrength() {
		let value = DataModelManager.shared.get(forKey: DataModelKeys.signalStrength, withDefault: 0)
		signalStrengthSegment.selectedSegment = value
	}
}
