//
//  NetworkRegistrationViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 28/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class NetworkRegistrationViewController: NSViewController, ModemModular {
	
	@IBOutlet weak var poweringOff: NSButton!
	@IBOutlet weak var poweredOff: NSButton!
	@IBOutlet weak var poweringOn: NSButton!
	@IBOutlet weak var poweredOn: NSButton!
	@IBOutlet weak var registrationDeniedStatus: NSButton!
	@IBOutlet weak var registeredRoamingStatus: NSButton!
	@IBOutlet weak var registeredHomeNetworkStatus: NSButton!
	@IBOutlet weak var registeringStatus: NSButton!
	@IBOutlet weak var unknownStatus: NSButton!
	@IBOutlet weak var notificationButton: NSButton!
	
	var buttonStatus: [NSButton: NetworkRegistrationStatus] = [:]
	
	var modemModule: ModemModule? {
		didSet {
			if let oldValue = oldValue, let key = modemModuleKeys[oldValue] {
				NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: key), object: nil)
			}
			
			if let newValue = modemModule, let key = modemModuleKeys[newValue] {
				NotificationCenter.default.addObserver(self,
				                                       selector: #selector(NetworkRegistrationViewController.statusChanged),
				                                       name: NSNotification.Name.init(rawValue: key),
				                                       object: nil)
			}
			
			modemChanged()
		}
	}
	
	@IBOutlet weak var liveUpdate: NSButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		buttonStatus[unknownStatus] = .unknown
		buttonStatus[registeringStatus] = .registering
		buttonStatus[registeredHomeNetworkStatus] = .registeredHomeNetwork
		buttonStatus[registeredRoamingStatus] = .registeredRoaming
		buttonStatus[registrationDeniedStatus] = .registrationDenied
		buttonStatus[poweringOff] = .poweringOff
		buttonStatus[poweredOff] = .poweredOff
		buttonStatus[poweringOn] = .poweringOn
		buttonStatus[poweredOn] = .poweredOn
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		updateStatus()
		modemChanged()
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(NetworkRegistrationViewController.modemChanged),
		                                       name: NSNotification.Name.init(rawValue: currentModemModuleKey),
		                                       object: nil)
	}
	
	override func viewDidDisappear() {
		super.viewDidDisappear()
		NotificationCenter.default.removeObserver(self)
	}
	
	func modemChanged() {
		DispatchQueue.main.async {
			if self.liveUpdate != nil {
				self.liveUpdate.isEnabled = ModemModule.isCurrent(self.modemModule)
				self.notificationButton.isEnabled = ModemModule.isCurrent(self.modemModule)
			}
		}
	}
	
	@IBAction func sendNotification(_ sender: AnyObject) {
		if ModemModule.isCurrent(self.modemModule) {
			do {
				try Server.default.send(notification: NetworkRegistrationStatusNotification(module: modemModule))
			} catch let error {
				log(error: "\(error)")
			}
		}
	}
	
	func liveNotification() {
		if liveUpdate.state == NSOnState && ModemModule.isCurrent(modemModule) {
			do {
				try Server.default.send(notification: NetworkRegistrationStatusNotification(module: modemModule))
			} catch let error {
				log(error: "\(error)")
			}
		}
	}
	
	@IBAction func statusValueChanged(_ sender: NSButton) {
		guard let status = buttonStatus[sender] else {
			return
		}
		guard let modemModule = modemModule else {
			return
		}
		guard let key = modemModuleKeys[modemModule] else {
			return
		}
		DataModelManager.shared.set(value: status,
		                            forKey: key,
		                            withNotification: false)
		liveNotification()
	}
	
	func status(withDefault defaultValue: NetworkRegistrationStatus = .unknown) -> NetworkRegistrationStatus {
		guard let modemModule = modemModule else {
			return .unknown
		}
		guard let key = modemModuleKeys[modemModule] else {
			return .unknown
		}
		let module = DataModelManager.shared.get(forKey: key, withDefault: defaultValue)
		return module
	}
	
	func statusChanged() {
		updateStatus()
	}
	
	func updateStatus() {
		switch status() {
		case .unknown: unknownStatus.state = NSOnState
		case .registering: registeringStatus.state = NSOnState
		case .registeredRoaming: registeredRoamingStatus.state = NSOnState
		case .registeredHomeNetwork: registeredHomeNetworkStatus.state = NSOnState
		case .registrationDenied: registrationDeniedStatus.state = NSOnState
		case .poweredOff: poweredOff.state = NSOnState
		case .poweredOn: poweredOn.state = NSOnState
		case .poweringOn: poweringOff.state = NSOnState
		case .poweringOff: poweringOn.state = NSOnState
		case .switching: break
		}
	}
}
