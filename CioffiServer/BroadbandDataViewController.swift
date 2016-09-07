//
//  BroadbandDataViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 9/08/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

extension BroadbandStreamingIPSpeed: CustomStringConvertible {
    public var description: String {
        switch self {
        case .kbps16: return "16 kbps"
        case .kbps32: return "32 kbps"
        case .kbps64: return "64 kbps"
        case .kbps128: return "128 kbps"
        case .kbps256: return "256 kbps"
        }
    }
}

class BroadbandDataViewController: NSViewController {
    
    @IBOutlet weak var autoNotification: NSButton!
    @IBOutlet weak var downlinkSpeedLabel: NSTextField!
    @IBOutlet weak var uplinkSpeedLabel: NSTextField!
    override func viewWillAppear() {
        super.viewWillAppear()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(BroadbandDataViewController.ipModeDidChange),
                                               name: NSNotification.Name.init(rawValue: broadbandDataModeKey),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(BroadbandDataViewController.uplinkSpeedDidChange),
                                               name: NSNotification.Name.init(rawValue: broadbandDataUplinkSpeedKey),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(BroadbandDataViewController.downlinkSpeedDidChange),
                                               name: NSNotification.Name.init(rawValue: broadbandDataDownlinkSpeedKey),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(BroadbandDataViewController.broadbandStatusDidChange),
                                               name: NSNotification.Name.init(rawValue: broadbandDataActiveModeKey),
                                               object: nil)
        
        updateIPMode()
        updateUplinkSpeed()
        updateDownlinkSpeed()
        updateStatus()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        NotificationCenter.default.removeObserver(self)
    }
    
    func ipModeDidChange() {
        DispatchQueue.main.async { 
            self.updateIPMode()
        }
    }
    
    func uplinkSpeedDidChange() {
        DispatchQueue.main.async {
            self.updateUplinkSpeed()
        }
    }
    
    func downlinkSpeedDidChange() {
        DispatchQueue.main.async {
            self.updateDownlinkSpeed()
        }
    }
    
    func broadbandStatusDidChange() {
        DispatchQueue.main.async {
            self.updateStatus()
        }
    }
    
    func updateControl<T: RawRepresentable>(`for` key : String, defaultValue: T, offset: Int) where T.RawValue == Int {
        let mode = DataModelManager.shared.get(forKey: key, withDefault: defaultValue)
        guard let control = view.viewWithTag(mode.rawValue + offset) as? NSButton else {
            log(warning: "Could not find view for \(mode) (\(mode.rawValue) + \(offset))")
            return
        }
        control.state = NSOnState
    }

    func updateIPMode() {
        updateControl(for: broadbandDataModeKey, defaultValue: BroadbandDataMode.standardIP, offset: 100)
    }
    
    func updateUplinkSpeed() {
        updateControl(for: broadbandDataUplinkSpeedKey, defaultValue: BroadbandStreamingIPSpeed.kbps16, offset: 200)
    }
    
    func updateDownlinkSpeed() {
        updateControl(for: broadbandDataDownlinkSpeedKey, defaultValue: BroadbandStreamingIPSpeed.kbps16, offset: 300)
    }
    
    func updateStatus() {
        updateControl(for: broadbandDataActiveModeKey, defaultValue: BroadbandDataStatus.dataInactive, offset: 400)
        updateStatusInfo()
    }
    
    func updateStatusInfo() {
        let mode = DataModelManager.shared.get(forKey: broadbandDataActiveModeKey, withDefault: BroadbandDataStatus.dataInactive)
        var uplinkText = "---"
        var downlinkText = "---"
        if mode != .dataInactive {
            uplinkText = DataModelManager.shared.get(forKey: broadbandDataActiveUplinkSpeedKey, withDefault: BroadbandStreamingIPSpeed.kbps16).description
            downlinkText = DataModelManager.shared.get(forKey: broadbandDataActiveDownlinkSpeedKey, withDefault: BroadbandStreamingIPSpeed.kbps16).description
        }
        uplinkSpeedLabel.stringValue = uplinkText
        downlinkSpeedLabel.stringValue = downlinkText
    }
    
    @IBAction func ipModeChanged(_ sender: NSButton) {
        let modeValue = sender.tag - 100
        guard let mode = BroadbandDataMode.init(rawValue: modeValue) else {
            log(warning: "Unknown BroadbandDataMode mode \(modeValue)")
            return
        }
        
        DataModelManager.shared.set(value: mode, forKey: broadbandDataModeKey, withNotification: false)
        updateStatus()
        sendNotification()
    }
    
    @IBAction func uplinkSpeedChanged(_ sender: NSButton) {
        let modeValue = sender.tag - 200
        guard let speed = BroadbandStreamingIPSpeed.init(rawValue: modeValue) else {
            log(warning: "Unknown BroadbandStreamingIPSpeed mode \(modeValue)")
            return
        }
        
        DataModelManager.shared.set(value: speed, forKey: broadbandDataUplinkSpeedKey, withNotification: false)
        updateStatus()
        sendNotification()
    }

    @IBAction func downlinkSpeedChanged(_ sender: NSButton) {
        let modeValue = sender.tag - 300
        guard let speed = BroadbandStreamingIPSpeed.init(rawValue: modeValue) else {
            log(warning: "Unknown BroadbandStreamingIPSpeed mode \(modeValue)")
            return
        }
        
        DataModelManager.shared.set(value: speed, forKey: broadbandDataDownlinkSpeedKey, withNotification: false)
        updateStatus()
        sendNotification()
    }
    
    @IBAction func statusModeChanged(_ sender: NSButton) {
        let modeValue = sender.tag - 400
        guard let status = BroadbandDataStatus.init(rawValue: modeValue) else {
            log(warning: "Unknown BroadbandDataStatus mode \(modeValue)")
            return
        }
        
        log(info: "Set SatelliteBroadbandDataMode to \(status)")
        DataModelManager.shared.set(value: status, forKey: broadbandDataActiveModeKey, withNotification: false)
        
        let uplink = DataModelManager.shared.get(forKey: broadbandDataUplinkSpeedKey, withDefault: BroadbandStreamingIPSpeed.kbps16)
        let downlink = DataModelManager.shared.get(forKey: broadbandDataDownlinkSpeedKey, withDefault: BroadbandStreamingIPSpeed.kbps16)
        DataModelManager.shared.set(value: uplink, forKey: broadbandDataActiveUplinkSpeedKey, withNotification: false)
        DataModelManager.shared.set(value: downlink, forKey: broadbandDataActiveDownlinkSpeedKey, withNotification: false)
        updateStatus()
        sendNotification()
    }
    
    @IBAction func sendNotificationAction(_ sender: AnyObject) {
        sendNotification(ignoreAuto: true)
    }
    
    func sendNotification(ignoreAuto: Bool = false) {
        if autoNotification.state == NSOnState || ignoreAuto {
            do {
                try Server.default.send(notification: BroadbandDataStatusNotification())
            } catch let error {
                log(info: "\(error)")
            }
        }
    }
}
