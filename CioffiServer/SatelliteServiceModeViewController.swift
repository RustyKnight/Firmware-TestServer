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
	
	@IBOutlet weak var liveUpdate: NSButton!
	@IBOutlet weak var modeSegment: NSSegmentedControl!
	@IBOutlet weak var notificationButton: NSButton!
	
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
		                                       name: DataModelKeys.satelliteServiceMode.notification,
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(SatelliteServiceModeViewController.modemChanged),
		                                       name: DataModelKeys.currentModemModule.notification,
		                                       object: nil)
		
		modemChanged()
		satelliteServiceModeChanged()
	}
	
	func modemChanged() {
		DispatchQueue.main.async {
			if self.liveUpdate != nil {
				self.liveUpdate.isEnabled = ModemModule.isCurrent(.satellite)
				self.notificationButton.isEnabled = ModemModule.isCurrent(.satellite)
				guard ModemModule.isCurrent(.satellite) else {
					return
				}
				let mode = DataModelManager.shared.get(forKey: DataModelKeys.satelliteServiceMode, withDefault: SatelliteServiceMode.voice)
				if mode != .data {
					DataModelManager.shared.set(value: BroadbandDataModeStatus.dataInactive, forKey: DataModelKeys.broadbandDataActiveMode)
				}
			}
		}
	}
	
	override func viewWillDisappear() {
		super.viewWillDisappear()
		NotificationCenter.default.removeObserver(self)
	}
	
	@IBAction func sendNotificationAction(_ sender: AnyObject) {
		sendNotification(forced: true)
	}
	
	@IBAction func modeWasChanged(_ sender: AnyObject) {
		let value = modeSegment.selectedSegment - 1
		guard let mode = values[value] else {
			return
		}
		DataModelManager.shared.set(value: mode, forKey: DataModelKeys.satelliteServiceMode)
		liveNotification()
	}
	
	func liveNotification() {
		sendNotification()
	}

	var isLiveUpdate: Bool {
		return liveUpdate.state == NSOnState
	}
	
	func sendNotification(forced: Bool = false) {
		if (forced || isLiveUpdate) && ModemModule.satellite.isCurrent {
			do {
				try Server.default.send(notification: SatelliteServiceModeNotification())
			} catch let error {
				log(error: "\(error)")
			}
		}
	}
	
	func satelliteServiceModeChanged() {
		guard Thread.isMainThread else {
			DispatchQueue.main.async(execute: {
				self.satelliteServiceModeChanged()
			})
			return
		}
		let mode = DataModelManager.shared.get(forKey: DataModelKeys.satelliteServiceMode, withDefault: SatelliteServiceMode.voice)
		modeSegment.selectedSegment = mode.rawValue + 1
	}
}
