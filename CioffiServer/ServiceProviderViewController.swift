//
//  ServiceProviderViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 28/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class ServiceProviderViewController: NSViewController {
	
	@IBOutlet weak var providerName: NSTextField!
	@IBOutlet weak var notificationButton: NSButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		providerName.stringValue = DataModelManager.shared.get(forKey: serviceProviderKey, withDefault: "")
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(NetworkRegistrationViewController.modemChanged),
		                                       name: NSNotification.Name.init(rawValue: currentModemModuleKey),
		                                       object: nil)
		modemChanged()
	}
	
	override func viewWillDisappear() {
		super.viewWillDisappear()
		modemChanged()
	}
	
	func modemChanged() {
		DispatchQueue.main.async {
			if self.notificationButton != nil {
				self.notificationButton.isEnabled = ModemModule.isCurrent(.cellular)
			}
		}
	}
	
	@IBAction func providerNameChanged(_ sender: AnyObject) {
		DataModelManager.shared.set(value: providerName.stringValue,
		                            forKey: serviceProviderKey,
		                            withNotification: false)
		sendNotification()
	}
	
	@IBAction func sendNotification(_ sender: AnyObject) {
		sendNotification()
	}
	
	func sendNotification() {
		if ModemModule.cellular.isCurrent {
			do {
				try Server.default.send(notification: ServiceProviderNotification())
			} catch let error {
				log(error: "\(error)")
			}
		}
	}
	
}
