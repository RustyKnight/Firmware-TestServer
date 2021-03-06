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
	
	@IBOutlet weak var networkModuleSegment: NSSegmentedControl!
	@IBOutlet weak var smartSwitchingMock: NSSegmentedControl!
	@IBOutlet weak var lifeCycleEvents: NSButton!
	
	var buttonModule: [Int: NetworkMode] = [:]
	var moduleButton: [NetworkMode: Int] = [:]
	var networkModeModemModule: [NetworkMode: ModemModule] = [
		.satellite: .satellite,
		.cellular: .cellular
	]
	var modemModuleNetworkMode: [ModemModule: NetworkMode] = [
		.satellite: .satellite,
		.cellular: .cellular
	]
	
	override func viewDidLoad() {
		super.viewDidLoad()
		buttonModule[0] = NetworkMode.satellite
		buttonModule[1] = NetworkMode.cellular
		buttonModule[2] = NetworkMode.smartSwitch
		
		moduleButton[NetworkMode.satellite] = 0
		moduleButton[NetworkMode.cellular] = 1
		moduleButton[NetworkMode.smartSwitch] = 2
		
		guard let networkMode = modemModuleNetworkMode[ModemModule.current] else {
			return
		}
		guard let index = moduleButton[networkMode] else {
			return
		}
		networkModuleSegment.selectedSegment = index
		
		updateModemModule(for: networkMode, withLifeCycle: true)
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(networkModeDataChanged),
		                                       name: DataModelKeys.networkMode.notification,
		                                       object: nil)
		updateNetworkMode()
	}
	
	override func viewDidDisappear() {
		super.viewWillDisappear()
		NotificationCenter.default.removeObserver(self)
	}
	
	@IBAction func networkModuleChanged(_ sender: AnyObject) {
		guard let module = buttonModule[networkModuleSegment.selectedSegment] else {
			log(warning: "Bad module @ \(networkModuleSegment.selectedSegment)")
			return
		}
		
		updateModemModule(for: module, withLifeCycle: lifeCycleEvents.state == NSControl.StateValue.on)
	}
	
//	@IBAction func networkModeChanged(_ sender: NSButton) {
//		guard  let mode = buttonMode[sender] else {
//			log(warning: "Unknown mode for button \(sender.stringValue)")
//			return
//		}
//		updateModemModule(from: mode)
//		DataModelManager.shared.set(value: mode, forKey: GetNetworkModeFunction.networkModeKey)
//	}
	
	var ignoreUpdate: Bool = false
	
	@objc func networkModeDataChanged(_ notification: NSNotification) {
		guard !ignoreUpdate else {
			return
		}
		updateNetworkMode()
	}
	
	func updateNetworkMode() {
		let mode = DataModelManager.shared.get(forKey: DataModelKeys.networkMode,
		                                       withDefault: NetworkMode.satellite)
		updateModemModule(for: mode, withLifeCycle: true)
		DispatchQueue.main.async {
			if let segment = self.moduleButton[mode] {
				self.networkModuleSegment.selectedSegment = segment
			}
		}
	}
	
	func updateModemModule(`for` mode: NetworkMode, withLifeCycle: Bool) {
		var modem: ModemModule = .unknown
		if mode == .smartSwitch {
			if smartSwitchingMock.selectedSegment == 0 {
				modem = .satellite
			} else {
				modem = .cellular
			}
			DataModelManager.shared.set(value: NetworkMode.smartSwitch, forKey: DataModelKeys.networkMode)
		} else {
			modem = networkModeModemModule[mode]!
			let mode = modem.networkMode
			defer {
				ignoreUpdate = false
			}
			ignoreUpdate = true
			DataModelManager.shared.set(value: mode, forKey: DataModelKeys.networkMode)
		}
		modem.makeCurrent(withLifeCycle: withLifeCycle)
	}
	
	var isSmartSwitching: Bool {
		let mode = DataModelManager.shared.get(forKey: DataModelKeys.networkMode,
		                                       withDefault: NetworkMode.satellite)
		return mode == NetworkMode.smartSwitch
	}
	
	@IBAction func smartSwitchingMockChanged(_ sender: AnyObject) {
		guard isSmartSwitching else {
			return
		}
		
		var mode: NetworkMode = .satellite
//		var modem: ModemModule = .unknown
		if smartSwitchingMock.selectedSegment == 0 {
//			modem = .satellite
			mode = .satellite
		} else {
//			modem = .cellular
			mode = .cellular
		}
//		modem.makeCurrent()
		updateModemModule(for: mode, withLifeCycle: true)
	}
}
