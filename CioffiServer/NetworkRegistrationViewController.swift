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
	
	@IBOutlet weak var unknownStateIndicator: NSButton!
	@IBOutlet weak var poweringOffStateIndicator: NSButton!
	@IBOutlet weak var poweredOffStateIndicator: NSButton!
	@IBOutlet weak var poweringOnStateIndicator: NSButton!
	@IBOutlet weak var poweredOnStateIndicator: NSButton!
	@IBOutlet weak var registeringStateIndicator: NSButton!
	@IBOutlet weak var registeredHomeStateIndicator: NSButton!
	@IBOutlet weak var registeredRoamingOffStateIndicator: NSButton!
	@IBOutlet weak var registeredDeniedStateIndicator: NSButton!
	
	var buttonStatus: [NSButton: NetworkRegistrationStatus] = [:]
	var statusIndicators: [NetworkRegistrationStatus: NSButton] = [:]
	
	var modemModule: ModemModule? {
		didSet {
			if let oldValue = oldValue, let key = targetNetworkRegistrationStateKeys[oldValue] {
				NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: key), object: nil)
			}
			
			if let newValue = modemModule {
				if let key = currentNetworkRegistrationStateKeys[newValue] {
					NotificationCenter.default.addObserver(self,
					                                       selector: #selector(NetworkRegistrationViewController.statusChanged),
					                                       name: NSNotification.Name.init(rawValue: key),
					                                       object: nil)
				}
				if let key = targetNetworkRegistrationStateKeys[newValue] {
					NotificationCenter.default.addObserver(self,
					                                       selector: #selector(NetworkRegistrationViewController.statusChanged),
					                                       name: NSNotification.Name.init(rawValue: key),
					                                       object: nil)
				}
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
		
		statusIndicators[.unknown] = unknownStateIndicator
		statusIndicators[.registering] = registeringStateIndicator
		statusIndicators[.registeredHomeNetwork] = registeredHomeStateIndicator
		statusIndicators[.registeredRoaming] = registeredRoamingOffStateIndicator
		statusIndicators[.registrationDenied] = registeredDeniedStateIndicator
		statusIndicators[.poweringOff] = poweringOffStateIndicator
		statusIndicators[.poweredOff] = poweredOffStateIndicator
		statusIndicators[.poweringOn] = poweringOnStateIndicator
		statusIndicators[.poweredOn] = poweredOnStateIndicator
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
		sendNotification(forced: true)
	}
	
	func sendNotification(forced: Bool = false) {
		guard let modemModule = modemModule else {
			return
		}
		if ModemModule.isCurrent(self.modemModule) {
			if liveUpdate.state == NSOnState || forced {
				guard let targetKey = targetNetworkRegistrationStateKeys[modemModule],
					let currentKey = currentNetworkRegistrationStateKeys[modemModule] else {
						return
				}
				let targetState = DataModelManager.shared.get(forKey: targetKey, withDefault: NetworkRegistrationStatus.poweredOff)
				
				DataModelManager.shared.set(value: targetState,
				                            forKey: currentKey)
				do {
					try Server.default.send(notification: NetworkRegistrationStatusNotification(module: modemModule))
				} catch let error {
					log(error: "\(error)")
				}
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
		guard let key = targetNetworkRegistrationStateKeys[modemModule] else {
			return
		}
		DataModelManager.shared.set(value: status,
		                            forKey: key,
		                            withNotification: false)
		sendNotification()
	}
	
	func currentStatus(withDefault defaultValue: NetworkRegistrationStatus = .unknown) -> NetworkRegistrationStatus {
		guard let modemModule = modemModule else {
			return .unknown
		}
		guard let key = currentNetworkRegistrationStateKeys[modemModule] else {
			return .unknown
		}
		let module = DataModelManager.shared.get(forKey: key, withDefault: defaultValue)
		return module
	}
	
	func targetStatus(withDefault defaultValue: NetworkRegistrationStatus = .unknown) -> NetworkRegistrationStatus {
		guard let modemModule = modemModule else {
			return .unknown
		}
		guard let key = targetNetworkRegistrationStateKeys[modemModule] else {
			return .unknown
		}
		let mode = DataModelManager.shared.get(forKey: key, withDefault: defaultValue)
		return mode
	}
	
	func statusChanged() {
		updateStatus()
	}
	
	func updateStatus() {
		switch targetStatus() {
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
		
		for (_, indicator) in statusIndicators {
			indicator.isHidden = true
		}
		
		guard let indicator = statusIndicators[currentStatus()] else {
			return
		}
		indicator.isHidden = false
	}
}
