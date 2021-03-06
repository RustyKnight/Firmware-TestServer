//
//  BatteryStatusViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 28/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

extension BatteryStatus: CustomStringConvertible {
	public var description: String {
		switch self {
		case .unknown: return "Unknown"
		case .charging: return "Charging"
		case .discharging: return "Discharging"
		case .notCharging: return "Not Charging"
		case .full: return "Full"
		}
	}
}

class BatteryStatusViewController: NSViewController {
	
	@IBOutlet weak var chargeLabel: NSTextField!
	@IBOutlet weak var chargeSlider: NSSlider!
	@IBOutlet weak var voltageField: NSTextField!
	@IBOutlet weak var presentCheck: NSButton!
	@IBOutlet weak var statusSegment: NSSegmentedControl!
	@IBOutlet weak var liveUpdate: NSButton!
	
	var percentageFormatter: NumberFormatter {
		let formatter = NumberFormatter()
		formatter.numberStyle = .percent
		formatter.maximumFractionDigits = 2
		return formatter
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		updateCharge()
		updateStatus()
		updateVoltage()
		updatePresent()
	}
	
	@IBAction func chargingValueChanged(_ sender: NSSlider) {
		let value = sender.integerValue
		chargeLabel.stringValue = percentageFormatter.string(from: NSNumber(value: Double(value) / Double(100.0)))!
		DataModelManager.shared.set(value: value, forKey: DataModelKeys.batteryCharge, withNotification: false)
		liveNotification()
	}
	
	@IBAction func statusValueChanged(_ sender: NSObject) {
		let value = statusSegment.selectedSegment
		guard let status = BatteryStatus(rawValue: value) else {
			return
		}
		DataModelManager.shared.set(value: status, forKey: DataModelKeys.batteryStatus, withNotification: false)
		liveNotification()
	}
	
	@IBAction func voltageValueChanged(_ sender: NSTextField) {
		let value = sender.doubleValue
		DataModelManager.shared.set(value: value, forKey: DataModelKeys.batteryVoltage, withNotification: false)
		liveNotification()
	}
	
	@IBAction func presentValueChanged(_ sender: NSButton) {
		let value = sender.state == NSControl.StateValue.on
		DataModelManager.shared.set(value: value, forKey: DataModelKeys.batteryPresent, withNotification: false)
		liveNotification()
	}
	
	@IBAction func sendNotification(_ sender: AnyObject) {
		do {
			try Server.default.send(notification: BatteryStatusNotification())
		} catch let error {
			log(error: "\(error)")
		}
	}
	
	func liveNotification() {
		if liveUpdate.state == NSControl.StateValue.on {
			do {
				try Server.default.send(notification: BatteryStatusNotification())
			} catch let error {
				log(error: "\(error)")
			}
		}
	}
	
	func updateCharge() {
		let value = DataModelManager.shared.get(forKey: DataModelKeys.batteryCharge, withDefault: 0)
		chargeSlider.integerValue = value
		chargeLabel.stringValue = percentageFormatter.string(from: NSNumber(value: Double(value) / 100.0))!
	}
	
	func status(withDefault defaultValue: BatteryStatus = .unknown) -> BatteryStatus {
		let value = DataModelManager.shared.get(forKey: DataModelKeys.batteryStatus, withDefault: defaultValue)
		return value
	}
	
	func updateStatus() {
		let statusValue = status()
		statusSegment.selectedSegment = statusValue.rawValue
	}
	
	func updateVoltage() {
		let value = DataModelManager.shared.get(forKey: DataModelKeys.batteryVoltage, withDefault: 0.0)
		voltageField.stringValue = String(value)
	}
	
	func updatePresent() {
		let value = DataModelManager.shared.get(forKey: DataModelKeys.batteryPresent, withDefault: false)
		presentCheck.state = value ? NSControl.StateValue.on : NSControl.StateValue.off
	}
}
