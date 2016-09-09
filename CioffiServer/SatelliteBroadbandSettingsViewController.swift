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
		
		updateIPMode()
		updateUplinkSpeed()
		updateDownlinkSpeed()
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
	
	@IBAction func ipModeChanged(_ sender: NSButton) {
		let modeValue = sender.tag - 100
		guard let mode = SatelliteBroadbandDataMode.init(rawValue: modeValue) else {
			log(warning: "Unknown BroadbandDataMode mode \(modeValue)")
			return
		}
		
		DataModelManager.shared.set(value: mode, forKey: satelliteBroadbandDataModeKey, withNotification: false)
	}
	
	@IBAction func uplinkSpeedChanged(_ sender: NSButton) {
		let modeValue = sender.tag - 200
		guard let speed = SatelliteBroadbandStreamingIPSpeed.init(rawValue: modeValue) else {
			log(warning: "Unknown BroadbandStreamingIPSpeed mode \(modeValue)")
			return
		}
		
		DataModelManager.shared.set(value: speed, forKey: satelliteBroadbandDataUplinkSpeedKey, withNotification: false)
	}
	
	@IBAction func downlinkSpeedChanged(_ sender: NSButton) {
		let modeValue = sender.tag - 300
		guard let speed = SatelliteBroadbandStreamingIPSpeed.init(rawValue: modeValue) else {
			log(warning: "Unknown BroadbandStreamingIPSpeed mode \(modeValue)")
			return
		}
		
		DataModelManager.shared.set(value: speed, forKey: satelliteBroadbandDataDownlinkSpeedKey, withNotification: false)
	}
}
