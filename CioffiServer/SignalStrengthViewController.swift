//
//  SignalStrengthViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 28/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class SignalStrengthViewController: NSViewController {

    @IBOutlet weak var satelliteMode: NSButton!
    @IBOutlet weak var cellularMode: NSButton!
    
    @IBOutlet weak var signalStrength: NSSlider!
    
    var buttonMode: [NSButton: SignalStrengthMode] = [:]
    
    @IBOutlet weak var liveUpdate: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonMode[satelliteMode] = SignalStrengthMode.satellite
        buttonMode[cellularMode] = SignalStrengthMode.cellular
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        updateModule()
        updateStrength()
    }
    
    @IBAction func modeSelectionChanged(_ sender: NSButton) {
        guard let mode = buttonMode[cellularMode] else {
            return
        }
        DataModelManager.shared.set(value: mode,
                                    forKey: activeSignalStrengthKey,
                                    withNotification: false)
        liveNotification()
    }
    
    @IBAction func signalStrengthValueChanged(_ sender: NSSlider) {
        let strength = sender.integerValue
        DataModelManager.shared.set(value: strength,
                                    forKey: signalStrengthKey,
                                    withNotification: false)
        liveNotification()
    }
    
    @IBAction func sendNotification(_ sender: NSButton) {
        do {
            try Server.default.send(notification: SignalStrengthNotification())
        } catch let error {
            log(error: "\(error)")
        }
    }
    
    func liveNotification() {
        if liveUpdate.state == NSOnState {
            do {
                try Server.default.send(notification: SignalStrengthNotification())
            } catch let error {
                log(error: "\(error)")
            }
        }
    }
    
    func mode(withDefault defaultValue: SignalStrengthMode = SignalStrengthMode.cellular) -> SignalStrengthMode {
        let module = DataModelManager.shared.get(forKey: activeSignalStrengthKey, withDefault: defaultValue)
        return module
    }
    
    func updateModule() {
        switch mode() {
        case .cellular: cellularMode.state = NSOnState
        case .satellite: satelliteMode.state = NSOnState
        }
    }
    
    func updateStrength() {
        let value = DataModelManager.shared.get(forKey: signalStrengthKey, withDefault: 0)
        signalStrength.integerValue = value
    }
}
