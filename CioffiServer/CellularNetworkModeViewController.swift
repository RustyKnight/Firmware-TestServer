//
//  CellularBroadbandDataViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 8/09/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class CellularNetworkModeViewController: NSViewController {
	
	@IBOutlet weak var broadbandDataSegement: NSSegmentedControl!
	@IBOutlet weak var liveUpdate: NSButton!
	@IBOutlet weak var sendNotification: NSButton!
	
	let modeToIndex: [CellularNetworkMode: Int] = [
		.unknown: 0,
		.cellular3G: 1,
		.cellular4G: 2
	]
	let indexToMode: [Int: CellularNetworkMode] = [
		0: .unknown,
		1: .cellular3G,
		2: .cellular4G
	]
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(NetworkRegistrationViewController.modemChanged),
		                                       name: DataModelKeys.currentModemModule.notification,
		                                       object: nil)
		stateDidChange()
		modemChanged()
	}
	
	override func viewWillDisappear() {
		super.viewWillDisappear()
		NotificationCenter.default.removeObserver(self)
	}
	
	func modemChanged() {
		DispatchQueue.main.async {
			if self.liveUpdate != nil {
				self.liveUpdate.isEnabled = ModemModule.isCurrent(.cellular)
				self.sendNotification.isEnabled = ModemModule.isCurrent(.cellular)
			}
		}
	}
	
	func stateDidChange() {
		let mode = DataModelManager.shared.get(forKey: DataModelKeys.cellularNetworkMode,
		                                       withDefault: CellularNetworkMode.unknown)
		
		guard let index = modeToIndex[mode] else {
			log(error: "Bad mode \(mode)")
			return
		}
		broadbandDataSegement.selectedSegment = index
	}
	
	@IBAction func activeStateDidChange(_ sender: AnyObject) {
	}
	
	@IBAction func sendNotification(_ sender: AnyObject) {
		sendNotification(forced: true)
	}
	
	@IBAction func selectedStateDidChange(_ sender: AnyObject) {
		guard let mode = indexToMode[broadbandDataSegement.selectedSegment] else {
			log(error: "Bad index = \(broadbandDataSegement.selectedSegment)")
			return
		}
		DataModelManager.shared.set(value: mode,
		                            forKey: DataModelKeys.cellularNetworkMode,
		                            withNotification: false)
	}
	
	var isLiveUpdate: Bool {
		return liveUpdate.state == NSControl.StateValue.on
	}
	
	func sendNotification(forced: Bool = false) {
		if (forced || isLiveUpdate) && ModemModule.cellular.isCurrent {
			do {
				try Server.default.send(notification: CellularNetworkModeNotification())
			} catch let error {
				log(info: "\(error)")
			}
		}
	}
}
