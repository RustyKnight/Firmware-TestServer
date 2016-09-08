//
//  NetworkModeViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class NetworkSelectionViewController: NSViewController {

    @IBOutlet weak var smartSwitchingNetworkMode: NSButton!
    @IBOutlet weak var cellularNetworkMode: NSButton!
    @IBOutlet weak var satelliteNetworkMode: NSButton!
    @IBOutlet weak var smartSwitchingMock: NSSegmentedControl!
    
    var buttonMode: [NSButton: NetworkMode] = [:]
    var networkMode: [NetworkMode: NSButton] = [:]
    
    var modemModule: [NetworkMode: ModemModule] = [
        .satellite: .satellite,
        .cellular: .cellular
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonMode[smartSwitchingNetworkMode] = NetworkMode.smartSwitch
        buttonMode[satelliteNetworkMode] = NetworkMode.satellite
        buttonMode[cellularNetworkMode] = NetworkMode.cellular
        
        networkMode[.cellular] = cellularNetworkMode
        networkMode[.satellite] = satelliteNetworkMode
        networkMode[.smartSwitch] = smartSwitchingNetworkMode
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(NetworkSelectionViewController.networkModeDataChanged),
                                               name: NSNotification.Name.init(rawValue: GetNetworkModeFunction.networkModeKey),
                                               object: nil)
        updateNetworkMode()
    }
    
    override func viewDidDisappear() {
        super.viewWillDisappear()
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func networkModeChanged(_ sender: NSButton) {
        guard  let mode = buttonMode[sender] else {
            log(warning: "Unknown mode for button \(sender.stringValue)")
            return
        }
        updateModemModule(from: mode)
        DataModelManager.shared.set(value: mode, forKey: GetNetworkModeFunction.networkModeKey)
    }
    
    func networkModeDataChanged(_ notification: NSNotification) {
        updateNetworkMode()
    }
    
    func updateNetworkMode() {
        let mode = DataModelManager.shared.get(forKey: GetNetworkModeFunction.networkModeKey,
                                               withDefault: NetworkMode.satellite)
        updateModemModule(from: mode)
        DispatchQueue.main.async {
            if let button = self.networkMode[mode] {
                button.state = NSOnState
            }
        }
    }
    
    func updateModemModule(from mode: NetworkMode) {
        var modem: ModemModule = .unknown
        if mode == .smartSwitch {
            if smartSwitchingMock.selectedSegment == 0 {
                modem = .satellite
            } else {
                modem = .cellular
            }
        } else {
            modem = modemModule[mode]!
        }
        modem.makeCurrent()
    }
    
    var isSmartSwitching: Bool {
        let mode = DataModelManager.shared.get(forKey: GetNetworkModeFunction.networkModeKey,
                                               withDefault: NetworkMode.satellite)
        return mode == NetworkMode.smartSwitch
    }
    
    @IBAction func smartSwitchingMockChanged(_ sender: AnyObject) {
        guard isSmartSwitching else {
            return
        }
        
        var modem: ModemModule = .unknown
        if smartSwitchingMock.selectedSegment == 0 {
            modem = .satellite
        } else {
            modem = .cellular
        }
        modem.makeCurrent()
    }
}
