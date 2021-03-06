//
//  RestrictedAccessViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class RestrictedAccessViewController: NSViewController {
	
	@IBOutlet weak var dataLocked: NSButton!
	@IBOutlet weak var callsLocked: NSButton!
	@IBOutlet weak var smsLocked: NSButton!
	@IBOutlet weak var adminLocked: NSButton!
	
	@IBOutlet weak var dataRestrcited: NSButton!
	@IBOutlet weak var callRestrcited: NSButton!
	@IBOutlet weak var smsRestrcited: NSButton!
	@IBOutlet weak var adminRestrcited: NSButton!
	
	@IBOutlet weak var adminPassword: NSSecureTextField!
	
	var restrictedStates: [NSButton: DataModelKey] = [:]
	var lockedStates: [NSButton: DataModelKey] = [:]
	var fieldStates: [NSTextField: DataModelKey] = [:]
	
	let selectedState: [Bool: NSControl.StateValue] = [
    true: NSControl.StateValue.on,
		false: NSControl.StateValue.off
	]
	
	override func viewDidLoad() {
		super.viewDidLoad()
		restrictedStates[dataRestrcited] = DataModelKeys.dataRestricition
		restrictedStates[callRestrcited] = DataModelKeys.callRestricition
		restrictedStates[smsRestrcited] = DataModelKeys.smsRestricition
		restrictedStates[adminRestrcited] = DataModelKeys.adminRestricition
		
		lockedStates[dataLocked] = DataModelKeys.dataLocked
		lockedStates[callsLocked] = DataModelKeys.callLocked
		lockedStates[smsLocked] = DataModelKeys.smsLocked
		lockedStates[adminLocked] = DataModelKeys.adminLocked
		
		fieldStates[adminPassword] = DataModelKeys.adminPassword
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(restrictedDataChanged),
		                                       name: DataModelKeys.dataRestricition.notification,
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(restrictedDataChanged),
		                                       name: DataModelKeys.callRestricition.notification,
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(restrictedDataChanged),
		                                       name: DataModelKeys.smsRestricition.notification,
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(restrictedDataChanged),
		                                       name: DataModelKeys.adminRestricition.notification,
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(lockedDataChanged),
		                                       name: DataModelKeys.dataLocked.notification,
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(lockedDataChanged),
		                                       name: DataModelKeys.callLocked.notification,
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(lockedDataChanged),
		                                       name: DataModelKeys.smsLocked.notification,
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(lockedDataChanged),
		                                       name: DataModelKeys.adminLocked.notification,
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(passwordDataChanged),
		                                       name: DataModelKeys.adminPassword.notification,
		                                       object: nil)
        updateRestrictedStates()
        updateLockedStates()
        updatePasswords()
	}
	
	override func viewWillDisappear() {
		super.viewWillDisappear()
		NotificationCenter.default.removeObserver(self)
	}
	
	@IBAction func lockedStateChanged(_ sender: NSButton) {
		guard let key = lockedStates[sender] else {
			return
		}
    
		let state = sender.state == NSControl.StateValue.on
		DataModelManager.shared.set(value: state,
		                            forKey: key,
		                            withNotification: false)
	}
	
	@IBAction func restrcitedStateChanged(_ sender: NSButton) {
		guard let key = restrictedStates[sender] else {
			return
		}
		let state = sender.state == NSControl.StateValue.on
		DataModelManager.shared.set(value: state,
		                            forKey: key,
		                            withNotification: false)
	}
	
	@IBAction func passwordStateChanged(_ sender: NSSecureTextField) {
		guard let key = fieldStates[sender] else {
			return
		}
		DataModelManager.shared.set(value: sender.stringValue,
		                            forKey: key,
		                            withNotification: false)
	}
	
	@objc func restrictedDataChanged(_ notification: NSNotification) {
		updateRestrictedStates()
	}
	
	
	@objc func lockedDataChanged(_ notification: NSNotification) {
		updateLockedStates()
	}
	
	@objc func passwordDataChanged(_ notification: NSNotification) {
		updatePasswords()
	}
	
	func update(button: NSButton, with key: DataModelKey) {
		let value = DataModelManager.shared.get(forKey: key, withDefault: false)
		guard let state = selectedState[value] else {
			return
		}
		button.state = state
	}
	
	func update(field: NSTextField, with key: DataModelKey) {
		let value = DataModelManager.shared.get(forKey: key, withDefault: "cioffi")
		field.stringValue = value
	}
	
	func updateRestrictedStates() {
		guard Thread.isMainThread else {
			DispatchQueue.main.async(execute: {
				self.updateRestrictedStates()
			})
			return
		}
		update(button: adminRestrcited, with: DataModelKeys.adminRestricition)
		update(button: smsRestrcited, with: DataModelKeys.smsRestricition)
		update(button: callRestrcited, with: DataModelKeys.callRestricition)
		update(button: dataRestrcited, with: DataModelKeys.dataRestricition)
	}
	
	func updateLockedStates() {
        log(info: "Thread.isMainThread")
		guard Thread.isMainThread else {
			DispatchQueue.main.async(execute: {
				self.updateLockedStates()
			})
			return
		}
		update(button: adminLocked, with: DataModelKeys.adminRestricition)
		update(button: smsLocked, with: DataModelKeys.smsRestricition)
		update(button: callsLocked, with: DataModelKeys.callRestricition)
		update(button: dataLocked, with: DataModelKeys.dataRestricition)
	}
	
	func updatePasswords() {
		guard Thread.isMainThread else {
			DispatchQueue.main.async(execute: {
				self.updateLockedStates()
			})
			return
		}
		update(field: adminPassword, with: DataModelKeys.adminPassword)
	}
}
