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
	
	var restrictedStates: [NSButton: String] = [:]
	var lockedStates: [NSButton: String] = [:]
	var fieldStates: [NSTextField: String] = [:]
	
	let selectedState: [Bool: Int] = [
		true: NSOnState,
		false: NSOnState
	]
	
	var ignoreUpdate = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		restrictedStates[dataRestrcited] = GetAccessRestricitionsFunction.dataRestricitionKey
		restrictedStates[callRestrcited] = GetAccessRestricitionsFunction.callRestricitionKey
		restrictedStates[smsRestrcited] = GetAccessRestricitionsFunction.smsRestricitionKey
		restrictedStates[adminRestrcited] = GetAccessRestricitionsFunction.adminRestricitionKey
		
		lockedStates[dataLocked] = GetAccessRestricitionsFunction.dataLockedKey
		lockedStates[callsLocked] = GetAccessRestricitionsFunction.callLockedKey
		lockedStates[smsLocked] = GetAccessRestricitionsFunction.smsLockedKey
		lockedStates[adminLocked] = GetAccessRestricitionsFunction.adminLockedKey
		
		fieldStates[adminPassword] = GetAccessRestricitionsFunction.adminPasswordKey
		
		updateRestrictedStates()
		updateLockedStates()
		updatePasswords();
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(RestrictedAccessViewController.restrictedDataChanged),
		                                       name: NSNotification.Name(rawValue: GetAccessRestricitionsFunction.dataRestricitionKey),
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(RestrictedAccessViewController.restrictedDataChanged),
		                                       name: NSNotification.Name(rawValue: GetAccessRestricitionsFunction.callRestricitionKey),
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(RestrictedAccessViewController.restrictedDataChanged),
		                                       name: NSNotification.Name(rawValue: GetAccessRestricitionsFunction.smsRestricitionKey),
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(RestrictedAccessViewController.restrictedDataChanged),
		                                       name: NSNotification.Name(rawValue: GetAccessRestricitionsFunction.adminRestricitionKey),
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(RestrictedAccessViewController.lockedDataChanged),
		                                       name: NSNotification.Name(rawValue: GetAccessRestricitionsFunction.dataLockedKey),
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(RestrictedAccessViewController.lockedDataChanged),
		                                       name: NSNotification.Name(rawValue: GetAccessRestricitionsFunction.callLockedKey),
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(RestrictedAccessViewController.lockedDataChanged),
		                                       name: NSNotification.Name(rawValue: GetAccessRestricitionsFunction.smsLockedKey),
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(RestrictedAccessViewController.lockedDataChanged),
		                                       name: NSNotification.Name(rawValue: GetAccessRestricitionsFunction.adminLockedKey),
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(RestrictedAccessViewController.passwordDataChanged),
		                                       name: NSNotification.Name(rawValue: GetAccessRestricitionsFunction.adminPasswordKey),
		                                       object: nil)
	}
	
	override func viewWillDisappear() {
		super.viewWillDisappear()
		NotificationCenter.default.removeObserver(self)
	}
	
	@IBAction func lockedStateChanged(_ sender: NSButton) {
		guard let key = lockedStates[sender] else {
			return
		}
		let state = sender.state == NSOnState
		ignoreUpdate = true
		DataModelManager.shared.set(value: state,
		                            forKey: key)
	}
	
	@IBAction func restrcitedStateChanged(_ sender: NSButton) {
		guard let key = restrictedStates[sender] else {
			return
		}
		let state = sender.state == NSOnState
		ignoreUpdate = true
		DataModelManager.shared.set(value: state,
		                            forKey: key)
	}
	
	@IBAction func passwordStateChanged(_ sender: NSSecureTextField) {
		guard let key = fieldStates[sender] else {
			return
		}
		ignoreUpdate = true
		DataModelManager.shared.set(value: sender.stringValue,
		                            forKey: key)
	}
	
	func restrictedDataChanged(_ notification: NSNotification) {
		updateRestrictedStates()
	}
	
	
	func lockedDataChanged(_ notification: NSNotification) {
		updateLockedStates()
	}
	
	func passwordDataChanged(_ notification: NSNotification) {
		updatePasswords()
	}
	
	func update(button: NSButton, with key: String) {
		guard let value = DataModelManager.shared.get(forKey: key, withDefault: false) as? Bool else {
			return
		}
		guard let state = selectedState[value] else {
			return
		}
		button.state = state
	}
	
	func update(field: NSTextField, with key: String) {
		guard let value = DataModelManager.shared.get(forKey: key, withDefault: false) as? String else {
			return
		}
		field.stringValue = value
	}
	
	func updateRestrictedStates() {
		guard !ignoreUpdate else {
			return
		}
		guard !Thread.isMainThread else {
			DispatchQueue.main.async(execute: {
				self.updateRestrictedStates()
			})
			return
		}
		update(button: adminRestrcited, with: GetAccessRestricitionsFunction.adminRestricitionKey)
		update(button: smsRestrcited, with: GetAccessRestricitionsFunction.smsRestricitionKey)
		update(button: callRestrcited, with: GetAccessRestricitionsFunction.callRestricitionKey)
		update(button: dataRestrcited, with: GetAccessRestricitionsFunction.dataRestricitionKey)
		ignoreUpdate = false
	}
	
	func updateLockedStates() {
		guard !ignoreUpdate else {
			return
		}
		guard !Thread.isMainThread else {
			DispatchQueue.main.async(execute: {
				self.updateLockedStates()
			})
			return
		}
		update(button: adminLocked, with: GetAccessRestricitionsFunction.adminRestricitionKey)
		update(button: smsLocked, with: GetAccessRestricitionsFunction.smsRestricitionKey)
		update(button: callsLocked, with: GetAccessRestricitionsFunction.callRestricitionKey)
		update(button: dataLocked, with: GetAccessRestricitionsFunction.dataRestricitionKey)
		ignoreUpdate = false
	}
	
	func updatePasswords() {
		guard !ignoreUpdate else {
			return
		}
		guard !Thread.isMainThread else {
			DispatchQueue.main.async(execute: {
				self.updateLockedStates()
			})
			return
		}
		update(field: adminPassword, with: GetAccessRestricitionsFunction.adminPasswordKey)
		ignoreUpdate = false
	}
}
