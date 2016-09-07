//
//  NetworkRegistrationViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 28/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class NetworkRegistrationViewController: NSViewController {

    @IBOutlet weak var cellularModule: NSButton!
    @IBOutlet weak var satelliteModule: NSButton!
    
    @IBOutlet weak var registrationDeniedStatus: NSButton!
    @IBOutlet weak var registeredRoamingStatus: NSButton!
    @IBOutlet weak var registeredHomeNetworkStatus: NSButton!
    @IBOutlet weak var registeringStatus: NSButton!
    @IBOutlet weak var unknownStatus: NSButton!
    
    var buttonModules: [NSButton: NetworkModule] = [:]
    var buttonStatus: [NSButton: NetworkRegistrationStatus] = [:]
    
    @IBOutlet weak var liveUpdate: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buttonModules[satelliteModule] = NetworkModule.satellite
        buttonModules[cellularModule] = NetworkModule.cellular
        
        buttonStatus[unknownStatus] = .unknown
        buttonStatus[registeringStatus] = .registering
        buttonStatus[registeredHomeNetworkStatus] = .registeredHomeNetwork
        buttonStatus[registeredRoamingStatus] = .registeredRoaming
        buttonStatus[registrationDeniedStatus] = .registrationDenied
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        updateModule()
        updateStatus()
    }
    
    @IBAction func sendNotification(_ sender: AnyObject) {
        do {
            try Server.default.send(notification: NetworkRegistrationStatusNotification())
        } catch let error {
            log(error: "\(error)")
        }
    }
    
    func liveNotification() {
        if liveUpdate.state == NSOnState {
            do {
                try Server.default.send(notification: NetworkRegistrationStatusNotification())
            } catch let error {
                log(error: "\(error)")
            }
        }
    }
    
    @IBAction func moduleValueChanged(_ sender: NSButton) {
        guard let module = buttonModules[sender] else {
            return
        }
        DataModelManager.shared.set(value: module,
                                    forKey: networkRegistrationModuleKey,
                                    withNotification: false)
        liveNotification()
    }
    
    @IBAction func statusValueChanged(_ sender: NSButton) {
        guard let status = buttonStatus[sender] else {
            return
        }
        DataModelManager.shared.set(value: status,
                                    forKey: networkRegistrationStatusKey,
                                    withNotification: false)
        liveNotification()
    }
    
    func module(withDefault defaultValue: NetworkModule = NetworkModule.cellular) -> NetworkModule {
        let module = DataModelManager.shared.get(forKey: networkRegistrationModuleKey, withDefault: defaultValue)
        return module
    }
    
    func updateModule() {
        switch module() {
        case .cellular: cellularModule.state = NSOnState
        case .satellite: satelliteModule.state = NSOnState
        }
    }
    
    func status(withDefault defaultValue: NetworkRegistrationStatus = .unknown) -> NetworkRegistrationStatus {
        let module = DataModelManager.shared.get(forKey: networkRegistrationStatusKey, withDefault: defaultValue)
        return module
    }
    
    func updateStatus() {
        switch status() {
        case .unknown: unknownStatus.state = NSOnState
        case .registering: registeringStatus.state = NSOnState
        case .registeredRoaming: registeredRoamingStatus.state = NSOnState
        case .registeredHomeNetwork: registeredHomeNetworkStatus.state = NSOnState
        case .registrationDenied: registrationDeniedStatus.state = NSOnState
        }
    }
}
