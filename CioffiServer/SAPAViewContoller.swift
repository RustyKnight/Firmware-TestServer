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
    return liveUpdate.state == NSControl.StateValue.on
  }
  
  var dispatchSource: DispatchSourceTimer?
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewWillAppear() {
    super.viewWillAppear()
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(automaticStateDidChange),
                                           name: DataModelKeys.automaticSAPAState.notification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(currentStateDidChange),
                                           name: DataModelKeys.sapaState.notification,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(modemChanged),
                                           name: DataModelKeys.currentModemModule.notification,
                                           object: nil)
    stateDidChange()
    modemChanged()
  }
  
  override func viewDidDisappear() {
    super.viewDidDisappear()
    NotificationCenter.default.removeObserver(self)
  }
  
  @objc func modemChanged() {
    DispatchQueue.main.async {
      if self.liveUpdate != nil {
        self.liveUpdate.isEnabled = ModemModule.isCurrent(.satellite)
        self.notificationButton.isEnabled = ModemModule.isCurrent(.satellite)
      }
    }
  }
  
  func stateDidChange() {
    let isAuto = DataModelManager.shared.get(forKey: DataModelKeys.automaticSAPAState, withDefault: true)
    let isActive = DataModelManager.shared.get(forKey: DataModelKeys.sapaState, withDefault: false)
    
    autoState.state = isAuto ? NSControl.StateValue.on : NSControl.StateValue.off
    currentState.state = isActive ? NSControl.StateValue.on : NSControl.StateValue.off
    
    updateDispatchTimer()
  }
  
  func updateDispatchTimer() {
    let isActive = DataModelManager.shared.get(forKey: DataModelKeys.sapaState, withDefault: false)
    guard isActive else {
      guard let dispatchSource = dispatchSource else {
        return
      }
      dispatchSource.setEventHandler(handler: nil)
      dispatchSource.cancel()
      self.dispatchSource = nil
      return
    }
    
    dispatchSource = DispatchSource.makeTimerSource()
    dispatchSource?.schedule(deadline: .now(), repeating: DispatchTimeInterval.milliseconds(14))
    dispatchSource?.setEventHandler(handler: {
      log(info: "Send SAPA signal strength notification")
      do {
        try Server.default.send(notification: SignalStrengthNotification())
      } catch let error {
        log(info: "Failed to send SAPA signal strength notification - \(error)")
        DataModelManager.shared.set(value: false, forKey: DataModelKeys.sapaState, withNotification: true)
      }
    })
    dispatchSource?.resume()
  }
  
  @objc func automaticStateDidChange() {
    DispatchQueue.main.async {
      self.stateDidChange()
    }
  }
  
  @objc func currentStateDidChange() {
    DispatchQueue.main.async {
      self.stateDidChange()
    }
  }
  
  @IBAction func activeStateChanged(_ sender: AnyObject) {
    let state = currentState.state == NSControl.StateValue.on
    DataModelManager.shared.set(value: state, forKey: DataModelKeys.sapaState, withNotification: false)
    sendNotification()
    updateDispatchTimer()
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
