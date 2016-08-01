//
//  SatelliteServiceModeViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 29/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

extension SatelliteServiceMode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .voice: return "Voice"
        case .data: return "Data"
        case .switchingToVoice: return "Switching to Voice"
        case .switchingToData: return "Switching to Data"
        }
    }
}

class SatelliteServiceModeViewController: NSViewController {

    @IBOutlet weak var modeSlider: NSSlider!
    @IBOutlet weak var liveUpdate: NSButton!
    @IBOutlet weak var modeLabel: NSTextField!
    
    let values: [Int: SatelliteServiceMode] = [
        SatelliteServiceMode.unknown.rawValue: .unknown,
        SatelliteServiceMode.voice.rawValue: .voice,
        SatelliteServiceMode.data.rawValue: .data,
        SatelliteServiceMode.switchingToData.rawValue: .switchingToData,
        SatelliteServiceMode.switchingToVoice.rawValue: .switchingToVoice,
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(SatelliteServiceModeViewController.satelliteServiceModeChanged),
                                               name: NSNotification.Name.init(rawValue: satelliteServiceModeKey),
                                               object: nil)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func sendNotificationAction(_ sender: AnyObject) {
        sendNotification()
    }
    
    @IBAction func slideValueChanged(_ sender: AnyObject) {
        let value = modeSlider.integerValue
        log(info: "value = \(value)")
        guard let mode = values[value] else {
            return
        }
        log(info: "mode = \(mode)")
        modeLabel.stringValue = mode.description
        DataModelManager.shared.set(value: value, forKey: satelliteServiceModeKey)
        liveNotification()
    }
    
    func liveNotification() {
        if liveUpdate.state == NSOnState {
            sendNotification()
        }
    }
    
    func sendNotification() {
        do {
            try Server.default.send(notification: SatelliteServiceModeNotification())
        } catch let error {
            log(error: "\(error)")
        }
    }
    
    func satelliteServiceModeChanged(_ notification: Notification) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async(execute: { 
                self.satelliteServiceModeChanged(notification)
            })
            return
        }
        let value = DataModelManager.shared.integer(forKey: satelliteServiceModeKey, withDefault: SatelliteServiceMode.voice.rawValue)
        guard let mode = SatelliteServiceMode(rawValue: value) else {
            return
        }
        modeSlider.integerValue = mode.rawValue
        modeLabel.stringValue = mode.description
    }
}
