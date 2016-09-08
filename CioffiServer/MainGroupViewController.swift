//
//  MainGroupViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 8/09/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

enum TabError: Error {
    case invalidViewController(name: String)
}

class MainGroupViewController: NSViewController {

    @IBOutlet weak var satelliteTabView: NSTabView!
    @IBOutlet weak var cellularTabView: NSTabView!
    @IBOutlet weak var commonTabView: NSTabView!
    
    @IBOutlet weak var serverActiveState: NSButton!
    
    @IBOutlet weak var majorVersionField: NSTextField!
    @IBOutlet weak var minorVersionField: NSTextField!
    @IBOutlet weak var patchVersionField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCommonTabs()
        setupSatelliteTabs()
        setupCellularTabs()
        
        ModemModule.satellite.makeCurrent()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        majorVersionField.stringValue = DataModelManager.shared.get(forKey: GetVersionFunction.majorVersionKey, withDefault: "1")
        minorVersionField.stringValue = DataModelManager.shared.get(forKey: GetVersionFunction.minorVersionKey, withDefault: "0")
        patchVersionField.stringValue = DataModelManager.shared.get(forKey: GetVersionFunction.patchVersionKey, withDefault: "0")
    }
    
    func setupCommonTabs() {
        do {
            commonTabView.addTabViewItem(try makeTab(withName: "Network Selection",
                                                        viewController: "NetworkSelectionStatus",
                                                        identifier: "NetworkSelectionStatus"))
            commonTabView.addTabViewItem(try makeTab(withName: "Restrictions",
                                                        viewController: "Restrictions",
                                                        identifier: "Restrictions"))
            commonTabView.addTabViewItem(try makeTab(withName: "Battery",
                                                        viewController: "BatteryStatus",
                                                        identifier: "BatteryStatus"))
        } catch let error {
            log(info: "\(error)")
        }
    }
    
    func setupSatelliteTabs() {
        do {
            satelliteTabView.addTabViewItem(try makeTab(withName: "Network Registration",
                                                     viewController: "NetworkRegistration",
                                                     identifier: "NetworkRegistration",
                                                     modemModule: .satellite))
            satelliteTabView.addTabViewItem(try makeTab(withName: "Broadband Data",
                                                        viewController: "SatelliteBroadbandData",
                                                        identifier: "SatelliteBroadbandData"))
            satelliteTabView.addTabViewItem(try makeTab(withName: "Signal Strength",
                                                        viewController: "SignalStrength",
                                                        identifier: "SignalStrength",
                                                        modemModule: .satellite))
            satelliteTabView.addTabViewItem(try makeTab(withName: "Antenna Pointing Assistance",
                                                        viewController: "SAPA",
                                                        identifier: "SAPA"))
            satelliteTabView.addTabViewItem(try makeTab(withName: "Service Mode",
                                                        viewController: "SatelliteServiceMode",
                                                        identifier: "SatelliteServiceMode"))
        } catch let error {
            log(info: "\(error)")
        }
    }
    
    func setupCellularTabs() {
        do {
            cellularTabView.addTabViewItem(try makeTab(withName: "Network Registration",
                                                        viewController: "NetworkRegistration",
                                                        identifier: "NetworkRegistration",
                                                        modemModule: .cellular))
            cellularTabView.addTabViewItem(try makeTab(withName: "Broadband Data",
                                                       viewController: "CellularBroadbandData",
                                                       identifier: "CellularBroadbandData"))
            cellularTabView.addTabViewItem(try makeTab(withName: "Signal Strength",
                                                        viewController: "SignalStrength",
                                                        identifier: "SignalStrength",
                                                        modemModule: .cellular))
            cellularTabView.addTabViewItem(try makeTab(withName: "Service Provider Name",
                                                       viewController: "ServiceProvider",
                                                       identifier: "ServiceProvider"))
        } catch let error {
            log(info: "\(error)")
        }
    }
    
    func makeTab(withName name: String, viewController: String, identifier: String, modemModule: ModemModule = .unknown) throws -> NSTabViewItem {
        let storyboard = NSStoryboard.init(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateController(withIdentifier: viewController) as? NSViewController else {
            throw TabError.invalidViewController(name: viewController)
        }
        if var vc = vc as? ModemModular {
            vc.modemModule = modemModule
        }
        let tabItem = NSTabViewItem(identifier: identifier)
        tabItem.label = name
        tabItem.viewController = vc
        return tabItem
    }
    
    @IBAction func powerDownAlert(_ sender: AnyObject) {
        send(notification: .powerButtonPressed)
    }
    
    @IBAction func criticalHighTempAlert(_ sender: AnyObject) {
        send(notification: .criticalHighTemperature)
    }
    
    @IBAction func criticialLowTempAlert(_ sender: AnyObject) {
        send(notification: .criticalLowTemperature)
    }
    
    @IBAction func flatBatteryAlert(_ sender: AnyObject) {
        send(notification: .batteryFlat)
    }
    
    func send(notification: SystemAlertType) {
        do {
            try Server.default.send(notification: SystemAlertNotification(type: notification))
        } catch let error {
            log(error: "\(error)")
        }
    }
    
    @IBAction func majorFieldChanged(_ sender: NSTextField) {
        DataModelManager.shared.set(value: sender.integerValue,
                                    forKey: GetVersionFunction.majorVersionKey)
    }
    
    @IBAction func minorFieldChanged(_ sender: NSTextField) {
        DataModelManager.shared.set(value: sender.integerValue,
                                    forKey: GetVersionFunction.minorVersionKey)
    }
    
    @IBAction func patchFieldChanged(_ sender: NSTextField) {
        DataModelManager.shared.set(value: sender.integerValue,
                                    forKey: GetVersionFunction.patchVersionKey)
    }
}
