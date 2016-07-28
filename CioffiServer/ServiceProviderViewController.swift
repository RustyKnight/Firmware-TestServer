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

    @IBOutlet weak var satelliteProvider: NSButton!
    @IBOutlet weak var cellularProvider: NSButton!
    
    @IBOutlet weak var liveUpdate: NSButton!
    
    var providerButtons: [NSButton: NetworkModule] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        providerButtons[satelliteProvider] = .satellite
        providerButtons[cellularProvider] = .cellular
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        providerName.stringValue = DataModelManager.shared.string(forKey: serviceProviderKey, withDefault: "")
        let module = DataModelManager.shared.networkModule(forKey: activeServiceProviderKey, withDefault: NetworkModule.cellular)
        switch module {
        case .cellular: cellularProvider.state = NSOnState
        case .satellite: satelliteProvider.state = NSOnState
        }
    }
    
    @IBAction func providerTypeChanged(_ sender: NSButton) {
        guard let value = providerButtons[sender] else {
            return
        }
        log(info: "value = \(value)")
        DataModelManager.shared.set(value: value.rawValue,
                                    forKey: activeServiceProviderKey,
                                    withNotification: false)
        liveNotification()
    }
    
    @IBAction func providerNameChanged(_ sender: AnyObject) {
        DataModelManager.shared.set(value: providerName.stringValue,
                                    forKey: serviceProviderKey,
                                    withNotification: false)
        liveNotification()
    }
    
    @IBAction func sendNotification(_ sender: AnyObject) {
        do {
            try Server.default.send(notification: ServiceProviderNotification())
        } catch let error {
            log(error: "\(error)")
        }
    }
    
    func liveNotification() {
        if liveUpdate.state == NSOnState {
            do {
                try Server.default.send(notification: ServiceProviderNotification())
            } catch let error {
                log(error: "\(error)")
            }
        }
    }

}
