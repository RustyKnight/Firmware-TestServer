//
//  ServerViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 3/08/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class ServerViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func stateDidChange(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on {
            do {
                try Server.default.start()
            } catch let error {
                log(error: "\(error)")
            }
        } else {
            Server.default.stop()
        }
    }
    
    @IBAction func powerButtonPressed(_ sender: NSButton) {
        send(notification: .powerButtonPressed)
    }
    
    @IBAction func powerCriticalHighTemp(_ sender: NSButton) {
        send(notification: .criticalHighTemperature)
    }
    
    @IBAction func powerCriticalLowTemp(_ sender: NSButton) {
        send(notification: .criticalLowTemperature)
    }
    
    @IBAction func powerFlatBattery(_ sender: NSButton) {
        send(notification: .batteryFlat)
    }
    
    func send(notification: SystemAlertType) {
        do {
            try Server.default.send(notification: SystemAlertNotification(type: notification))
        } catch let error {
            log(error: "\(error)")
        }
    }
}
