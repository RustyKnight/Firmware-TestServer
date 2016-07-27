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
        
        updateRestrictedStates()
        updateLockedStates()
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
    
    func restrictedDataChanged(_ notification: NSNotification) {
        updateRestrictedStates()
    }
    
    
    func lockedDataChanged(_ notification: NSNotification) {
        updateLockedStates()
    }
    
    func update(_ button: NSButton, with key: String) {
        guard let value = DataModelManager.shared.get(forKey: key, withDefault: false) as? Bool else {
            return
        }
        guard let state = selectedState[value] else {
            return
        }
        button.state = state
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
        update(adminRestrcited, with: GetAccessRestricitionsFunction.adminRestricitionKey)
        update(smsRestrcited, with: GetAccessRestricitionsFunction.smsRestricitionKey)
        update(callRestrcited, with: GetAccessRestricitionsFunction.callRestricitionKey)
        update(dataRestrcited, with: GetAccessRestricitionsFunction.dataRestricitionKey)
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
        update(adminLocked, with: GetAccessRestricitionsFunction.adminRestricitionKey)
        update(smsLocked, with: GetAccessRestricitionsFunction.smsRestricitionKey)
        update(callsLocked, with: GetAccessRestricitionsFunction.callRestricitionKey)
        update(dataLocked, with: GetAccessRestricitionsFunction.dataRestricitionKey)
        ignoreUpdate = false
    }
}
