//
//  BroadbandDataViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 9/08/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

extension SatelliteBroadbandStreamingIPSpeed: CustomStringConvertible {
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
                                               name: NSNotification.Name.init(rawValue: satelliteBroadbandDataModeKey),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(BroadbandDataViewController.uplinkSpeedDidChange),
                                               name: NSNotification.Name.init(rawValue: satelliteBroadbandDataUplinkSpeedKey),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(BroadbandDataViewController.downlinkSpeedDidChange),
                                               name: NSNotification.Name.init(rawValue: satelliteBroadbandDataDownlinkSpeedKey),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(BroadbandDataViewController.broadbandStatusDidChange),
                                               name: NSNotification.Name.init(rawValue: satelliteBroadbandDataActiveModeKey),
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
        updateControl(for: satelliteBroadbandDataModeKey, defaultValue: SatelliteBroadbandDataMode.standardIP, offset: 100)
    }
    
    func updateUplinkSpeed() {
        updateControl(for: satelliteBroadbandDataUplinkSpeedKey, defaultValue: SatelliteBroadbandStreamingIPSpeed.kbps16, offset: 200)
    }
    
    func updateDownlinkSpeed() {
        updateControl(for: satelliteBroadbandDataDownlinkSpeedKey, defaultValue: SatelliteBroadbandStreamingIPSpeed.kbps16, offset: 300)
    }
    
    func updateStatus() {
        updateControl(for: satelliteBroadbandDataActiveModeKey, defaultValue: SatelliteBroadbandDataStatus.dataInactive, offset: 400)
        updateStatusInfo()
    }
    
    func updateStatusInfo() {
        let mode = DataModelManager.shared.get(forKey: satelliteBroadbandDataActiveModeKey, withDefault: SatelliteBroadbandDataStatus.dataInactive)
        var uplinkText = "---"
        var downlinkText = "---"
        if mode != .dataInactive {
            uplinkText = DataModelManager.shared.get(forKey: satelliteBroadbandDataActiveUplinkSpeedKey, withDefault: SatelliteBroadbandStreamingIPSpeed.kbps16).description
            downlinkText = DataModelManager.shared.get(forKey: satelliteBroadbandDataActiveDownlinkSpeedKey, withDefault: SatelliteBroadbandStreamingIPSpeed.kbps16).description
        }
        uplinkSpeedLabel.stringValue = uplinkText
        downlinkSpeedLabel.stringValue = downlinkText
    }
    
    @IBAction func ipModeChanged(_ sender: NSButton) {
        let modeValue = sender.tag - 100
        guard let mode = SatelliteBroadbandDataMode.init(rawValue: modeValue) else {
            log(warning: "Unknown BroadbandDataMode mode \(modeValue)")
            return
        }
        
        DataModelManager.shared.set(value: mode, forKey: satelliteBroadbandDataModeKey, withNotification: false)
        updateStatus()
        sendNotification()
    }
    
    @IBAction func uplinkSpeedChanged(_ sender: NSButton) {
        let modeValue = sender.tag - 200
        guard let speed = SatelliteBroadbandStreamingIPSpeed.init(rawValue: modeValue) else {
            log(warning: "Unknown BroadbandStreamingIPSpeed mode \(modeValue)")
            return
        }
        
        DataModelManager.shared.set(value: speed, forKey: satelliteBroadbandDataUplinkSpeedKey, withNotification: false)
        updateStatus()
        sendNotification()
    }

    @IBAction func downlinkSpeedChanged(_ sender: NSButton) {
        let modeValue = sender.tag - 300
        guard let speed = SatelliteBroadbandStreamingIPSpeed.init(rawValue: modeValue) else {
            log(warning: "Unknown BroadbandStreamingIPSpeed mode \(modeValue)")
            return
        }
        
        DataModelManager.shared.set(value: speed, forKey: satelliteBroadbandDataDownlinkSpeedKey, withNotification: false)
        updateStatus()
        sendNotification()
    }
    
    @IBAction func statusModeChanged(_ sender: NSButton) {
        let modeValue = sender.tag - 400
        guard let status = SatelliteBroadbandDataStatus.init(rawValue: modeValue) else {
            log(warning: "Unknown BroadbandDataStatus mode \(modeValue)")
            return
        }
        
        DataModelManager.shared.set(value: status, forKey: satelliteBroadbandDataActiveModeKey, withNotification: false)
        
        let uplink = DataModelManager.shared.get(forKey: satelliteBroadbandDataUplinkSpeedKey, withDefault: SatelliteBroadbandStreamingIPSpeed.kbps16)
        let downlink = DataModelManager.shared.get(forKey: satelliteBroadbandDataDownlinkSpeedKey, withDefault: SatelliteBroadbandStreamingIPSpeed.kbps16)
        DataModelManager.shared.set(value: uplink, forKey: satelliteBroadbandDataActiveUplinkSpeedKey, withNotification: false)
        DataModelManager.shared.set(value: downlink, forKey: satelliteBroadbandDataActiveDownlinkSpeedKey, withNotification: false)
        updateStatus()
        sendNotification()
    }
    
    @IBAction func sendNotificationAction(_ sender: AnyObject) {
        sendNotification(ignoreAuto: true)
    }
    
    func sendNotification(ignoreAuto: Bool = false) {
        if autoNotification.state == NSOnState || ignoreAuto {
            do {
                try Server.default.send(notification: SatelliteBroadbandDataStatusNotification())
            } catch let error {
                log(info: "\(error)")
            }
        }
    }
}
