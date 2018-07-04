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
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(ipModeDidChange),
		                                       name: DataModelKeys.satelliteBroadbandDataMode.notification,
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(uplinkSpeedDidChange),
		                                       name: DataModelKeys.satelliteBroadbandDataUplinkSpeed.notification,
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(downlinkSpeedDidChange),
		                                       name: DataModelKeys.satelliteBroadbandDataDownlinkSpeed.notification,
		                                       object: nil)
		
		updateIPMode()
		updateUplinkSpeed()
		updateDownlinkSpeed()
	}
	
	override func viewDidDisappear() {
		super.viewDidDisappear()
		NotificationCenter.default.removeObserver(self)
	}
	
	@objc func ipModeDidChange() {
		DispatchQueue.main.async {
			self.updateIPMode()
		}
	}
	
	@objc func uplinkSpeedDidChange() {
		DispatchQueue.main.async {
			self.updateUplinkSpeed()
		}
	}
	
	@objc func downlinkSpeedDidChange() {
		DispatchQueue.main.async {
			self.updateDownlinkSpeed()
		}
	}
	
	func updateControl<T: RawRepresentable>(`for` key: DataModelKey, defaultValue: T, offset: Int) where T.RawValue == Int {
		let mode = DataModelManager.shared.get(forKey: key, withDefault: defaultValue)
		guard let control = view.viewWithTag(mode.rawValue + offset) as? NSButton else {
			log(warning: "Could not find view for \(mode) (\(mode.rawValue) + \(offset))")
			return
		}
		control.state = NSControl.StateValue.on
	}
	
	func updateIPMode() {
		updateControl(for: DataModelKeys.satelliteBroadbandDataMode, defaultValue: SatelliteBroadbandDataMode.standardIP, offset: 100)
	}
	
	func updateUplinkSpeed() {
		updateControl(for: DataModelKeys.satelliteBroadbandDataUplinkSpeed, defaultValue: SatelliteBroadbandStreamingIPSpeed.kbps16, offset: 200)
	}
	
	func updateDownlinkSpeed() {
		updateControl(for: DataModelKeys.satelliteBroadbandDataDownlinkSpeed, defaultValue: SatelliteBroadbandStreamingIPSpeed.kbps16, offset: 300)
	}
	
	@IBAction func ipModeChanged(_ sender: NSButton) {
		let modeValue = sender.tag - 100
		guard let mode = SatelliteBroadbandDataMode.init(rawValue: modeValue) else {
			log(warning: "Unknown BroadbandDataMode mode \(modeValue)")
			return
		}
		
		DataModelManager.shared.set(value: mode, forKey: DataModelKeys.satelliteBroadbandDataMode, withNotification: false)
	}
	
	@IBAction func uplinkSpeedChanged(_ sender: NSButton) {
		let modeValue = sender.tag - 200
		guard let speed = SatelliteBroadbandStreamingIPSpeed.init(rawValue: modeValue) else {
			log(warning: "Unknown BroadbandStreamingIPSpeed mode \(modeValue)")
			return
		}
		
		DataModelManager.shared.set(value: speed, forKey: DataModelKeys.satelliteBroadbandDataUplinkSpeed, withNotification: false)
	}
	
	@IBAction func downlinkSpeedChanged(_ sender: NSButton) {
		let modeValue = sender.tag - 300
		guard let speed = SatelliteBroadbandStreamingIPSpeed.init(rawValue: modeValue) else {
			log(warning: "Unknown BroadbandStreamingIPSpeed mode \(modeValue)")
			return
		}
		
		DataModelManager.shared.set(value: speed, forKey: DataModelKeys.satelliteBroadbandDataDownlinkSpeed, withNotification: false)
	}
}
