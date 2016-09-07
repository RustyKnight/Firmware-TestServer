//
//  NetworkModeViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class NetworkModeViewController: NSViewController {

    @IBOutlet weak var smartSwitchingNetworkMode: NSButton!
    @IBOutlet weak var cellularNetworkMode: NSButton!
    @IBOutlet weak var satelliteNetworkMode: NSButton!
    
    var buttonMode: [NSButton: NetworkMode] = [:]
    var networkMode: [NetworkMode: NSButton] = [:]
    
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
                                               selector: #selector(NetworkModeViewController.networkModeDataChanged),
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
        DataModelManager.shared.set(value: mode, forKey: GetNetworkModeFunction.networkModeKey)
    }
    
    func networkModeDataChanged(_ notification: NSNotification) {
        updateNetworkMode()
    }
    
    func updateNetworkMode() {
        let mode = DataModelManager.shared.get(forKey: GetNetworkModeFunction.networkModeKey, withDefault: NetworkMode.satellite)
        DispatchQueue.main.async {
            if let button = self.networkMode[mode] {
                button.state = NSOnState
            }
        }
    }
}
