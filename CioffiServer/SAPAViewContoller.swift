//
//  SAPAViewContoller.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 8/09/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class SAPAViewContoller: NSViewController {

    @IBOutlet weak var currentState: NSButton!
    @IBOutlet weak var autoState: NSButton!
    
    @IBOutlet weak var liveUpdate: NSButton!
    @IBOutlet weak var notificationButton: NSButton!
    
    var isLiveUpdate: Bool {
        return liveUpdate.state == NSOnState
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(SAPAViewContoller.automaticStateDidChange),
                                               name: NSNotification.Name.init(rawValue: automaticSAPAState),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(SAPAViewContoller.currentStateDidChange),
                                               name: NSNotification.Name.init(rawValue: sapaState),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(NetworkRegistrationViewController.modemChanged),
                                               name: NSNotification.Name.init(rawValue: currentModemModuleKey),
                                               object: nil)
        stateDidChange()
        modemChanged()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        NotificationCenter.default.removeObserver(self)
    }
    
    func modemChanged() {
        DispatchQueue.main.async {
            if self.liveUpdate != nil {
                self.liveUpdate.isEnabled = ModemModule.isCurrent(.satellite)
                self.notificationButton.isEnabled = ModemModule.isCurrent(.satellite)
            }
        }
    }
    
    func stateDidChange() {
        let isAuto = DataModelManager.shared.get(forKey: automaticSAPAState, withDefault: true)
        let isActive = DataModelManager.shared.get(forKey: sapaState, withDefault: false)
        
        autoState.state = isAuto ? NSOnState : NSOffState
        currentState.state = isActive ? NSOnState : NSOffState
    }
    
    func automaticStateDidChange() {
        DispatchQueue.main.async {
            self.stateDidChange()
        }
    }
    
    func currentStateDidChange() {
        DispatchQueue.main.async {
            self.stateDidChange()
        }
    }
    
    @IBAction func activeStateChanged(_ sender: AnyObject) {
        let state = currentState.state == NSOnState
        DataModelManager.shared.set(value: state, forKey: sapaState, withNotification: false)
        sendNotification()
    }
    
    func sendNotification(forced: Bool = false) {
        if (forced || isLiveUpdate) && ModemModule.satellite.isCurrent {
            do {
                try Server.default.send(notification: SAPAStatusNotification())
            } catch let error {
                log(info: "\(error)")
            }
        }
    }
    
}
