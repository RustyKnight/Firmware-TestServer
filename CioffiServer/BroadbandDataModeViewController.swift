//
//  BroadbandDataModeViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 9/09/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class BroadbandDataModeViewController: NSViewController {
	
	@IBOutlet weak var liveUpdateButton: NSButton!
	@IBOutlet weak var sendNotifcationButton: NSButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()

		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(BroadbandDataModeViewController.modeDidChange),
		                                       name: DataModelKeys.broadbandDataActiveMode.notification,
		                                       object: nil)
		
		updateControl(for: DataModelKeys.broadbandDataActiveMode, defaultValue: BroadbandDataModeStatus.dataInactive, offset: 400)
	}
	
	override func viewDidDisappear() {
		super.viewDidDisappear()
		NotificationCenter.default.removeObserver(self)
	}
	
	func modeDidChange() {
		updateControl(for: DataModelKeys.broadbandDataActiveMode, defaultValue: BroadbandDataModeStatus.dataInactive, offset: 400)
	}

	func updateControl<T: RawRepresentable>(`for` key : DataModelKey, defaultValue: T, offset: Int) where T.RawValue == Int {
		let mode = DataModelManager.shared.get(forKey: key, withDefault: defaultValue)
		guard let control = view.viewWithTag(mode.rawValue + offset) as? NSButton else {
			log(warning: "Could not find view for \(mode) (\(mode.rawValue) + \(offset))")
			return
		}
		control.state = NSOnState
	}
	
	@IBAction func statusModeChanged(_ sender: NSButton) {
		let modeValue = sender.tag - 400
		guard let status = BroadbandDataModeStatus.init(rawValue: modeValue) else {
			log(warning: "Unknown BroadbandDataStatus mode \(modeValue)")
			return
		}
		
		DataModelManager.shared.set(value: status, forKey: DataModelKeys.broadbandDataActiveMode, withNotification: false)
		
		let uplink = DataModelManager.shared.get(forKey: DataModelKeys.satelliteBroadbandDataUplinkSpeed, withDefault: SatelliteBroadbandStreamingIPSpeed.kbps16)
		let downlink = DataModelManager.shared.get(forKey: DataModelKeys.satelliteBroadbandDataDownlinkSpeed, withDefault: SatelliteBroadbandStreamingIPSpeed.kbps16)
		DataModelManager.shared.set(value: uplink, forKey: DataModelKeys.satelliteBroadbandDataActiveUplinkSpeed, withNotification: false)
		DataModelManager.shared.set(value: downlink, forKey: DataModelKeys.satelliteBroadbandDataActiveDownlinkSpeed, withNotification: false)
		updateControl(for: DataModelKeys.broadbandDataActiveMode, defaultValue: BroadbandDataModeStatus.dataInactive, offset: 400)
		sendNotification()
	}
	
	@IBAction func sendNotificationAction(_ sender: AnyObject) {
		sendNotification(ignoreAuto: true)
	}
	
	func sendNotification(ignoreAuto: Bool = false) {
		if liveUpdateButton.state == NSOnState || ignoreAuto {
			do {
				try Server.default.send(notification: BroadbandDataModeStatusNotification())
			} catch let error {
				log(info: "\(error)")
			}
		}
	}
}
