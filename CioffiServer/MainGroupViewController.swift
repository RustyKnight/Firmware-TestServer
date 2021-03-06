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
	
	@IBOutlet weak var callStatusPopupMenu: NSPopUpButton!
	
	@IBOutlet weak var satelliteTabView: NSTabView!
	@IBOutlet weak var cellularTabView: NSTabView!
	@IBOutlet weak var commonTabView: NSTabView!
	
	@IBOutlet weak var serverActiveState: NSButton!
	
	@IBOutlet weak var majorVersionField: NSTextField!
	@IBOutlet weak var minorVersionField: NSTextField!
	@IBOutlet weak var patchVersionField: NSTextField!
	
	@IBOutlet weak var missedCallCountField: NSTextFieldCell!
	
	@IBOutlet weak var simMissingButton: NSButton!
	@IBOutlet weak var simPukLockedButton: NSButton!
	@IBOutlet weak var simPinLockedButton: NSButton!
	@IBOutlet weak var simUnlockedButton: NSButton!
	
	@IBOutlet weak var unreadMessageCount: NSTextField!
	
	var buttonToSIMStatus: [NSButton: SIMStatus] = [:]
//	var simStatusToButton: [SIMStatus: NSButton] = [:]
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
//		buttonToSIMStatus[simUnlockedButton] = .unlocked
//		buttonToSIMStatus[simPinLockedButton] = .pinLocked
//		buttonToSIMStatus[simPukLockedButton] = .pukLocked
//		buttonToSIMStatus[simMissingButton] = .simMissing
//
//		simStatusToButton[.unlocked] = simUnlockedButton
//		simStatusToButton[.pinLocked] = simPinLockedButton
//		simStatusToButton[.pukLocked] = simPukLockedButton
//		simStatusToButton[.simMissing] = simMissingButton
		
		setupCommonTabs()
		setupSatelliteTabs()
		setupCellularTabs()
		
		ModemModule.satellite.makeCurrent()
		
		_ = RequestHandlerManager.default
		
		do {
			try Server.default.start()
		} catch let error {
			log(error: "\(error)")
		}
		
		for address in getIFAddresses() {
			log(info: address)
		}

		callStatusPopupMenu.removeAllItems()
		callStatusPopupMenu.addItems(withTitles: ["None", "Outgoing", "Incoming"])
		
		updateSIMLockStatus()
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		majorVersionField.stringValue = String(DataModelManager.shared.get(forKey: DataModelKeys.majorVersion, withDefault: 1))
		minorVersionField.stringValue = String(DataModelManager.shared.get(forKey: DataModelKeys.minorVersion, withDefault: 0))
		patchVersionField.stringValue = String(DataModelManager.shared.get(forKey: DataModelKeys.patchVersion, withDefault: 0))

		missedCallCountField.stringValue = String(DataModelManager.shared.get(forKey: DataModelKeys.missedCallCount, withDefault: 0))
		unreadMessageCount.stringValue = String(DataModelManager.shared.get(forKey: DataModelKeys.unreadMessageCount, withDefault: 0))
		
		autoUnreadMessagesCountAction(self)

		NotificationCenter.default.addObserver(self,
				selector: #selector(missedCallCountWasChanged),
				name: DataModelKeys.missedCallCount.notification,
				object: nil)

		NotificationCenter.default.addObserver(self,
				selector: #selector(simStatusDidChange),
				name: DataModelKeys.simStatus.notification,
				object: nil)
		
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(unreadMessagesCountChanged),
		                                       name: DataModelKeys.unreadMessageCount.notification,
		                                       object: nil)
	}

	var ignoreMissedCallCountChange = false

	@objc func unreadMessagesCountChanged(_ notification: Notification) {
		let count = DataModelManager.shared.get(forKey: DataModelKeys.unreadMessageCount, withDefault: 0)
		unreadMessageCount.stringValue = "\(count)"
	}

	@objc func missedCallCountWasChanged(_ notification: Notification) {
		defer {
			ignoreMissedCallCountChange = false
		}
		ignoreMissedCallCountChange = true
		let count = DataModelManager.shared.get(forKey: DataModelKeys.missedCallCount, withDefault: 0)
		missedCallCountField.stringValue = "\(count)"
	}

	@objc func simStatusDidChange(_ notification: Notification) {
//		let status = DataModelManager.shared.get(forKey: DataModelKeys.simStatus, withDefault: SIMStatus.unlocked)
//		simStatusToButton[status]?.state = NSControl.StateValue.on
	}
	
	func setupCommonTabs() {
		do {
			commonTabView.addTabViewItem(try makeTab(withName: "Network Selection",
			                                         viewController: "NetworkSelectionStatus",
			                                         identifier: "NetworkSelectionStatus"))
			commonTabView.addTabViewItem(try makeTab(withName: "Broadband Data Mode",
			                                         viewController: "BroadbandDataMode",
			                                         identifier: "BroadbandDataMode"))
			commonTabView.addTabViewItem(try makeTab(withName: "Restrictions",
			                                         viewController: "Restrictions",
			                                         identifier: "Restrictions"))
			commonTabView.addTabViewItem(try makeTab(withName: "Battery",
			                                         viewController: "BatteryStatus",
			                                         identifier: "BatteryStatus"))
			commonTabView.addTabViewItem(try makeTab(withName: "Wifi Configuration",
			                                         viewController: "WiFiConfiguration",
			                                         identifier: "WiFiConfiguration"))
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
			satelliteTabView.addTabViewItem(try makeTab(withName: "Broadband Data Settings",
			                                            viewController: "SatelliteBroadbandDataSettings",
			                                            identifier: "SatelliteBroadbandDataSettings"))
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
			cellularTabView.addTabViewItem(try makeTab(withName: "Network Mode",
			                                           viewController: "CellularNetworkMode",
			                                           identifier: "CellularNetworkMode"))
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
    let storyboard = NSStoryboard.init(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
    guard let vc = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: viewController)) as? NSViewController else {
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
		                            forKey: DataModelKeys.majorVersion)
	}
	
	@IBAction func minorFieldChanged(_ sender: NSTextField) {
		DataModelManager.shared.set(value: sender.integerValue,
		                            forKey: DataModelKeys.minorVersion)
	}
	
	@IBAction func patchFieldChanged(_ sender: NSTextField) {
		DataModelManager.shared.set(value: sender.integerValue,
		                            forKey: DataModelKeys.patchVersion)
	}
	
	func getIFAddresses() -> [String] {
		var addresses = [String]()
		
		// Get list of all interfaces on the local machine:
		var ifaddr : UnsafeMutablePointer<ifaddrs>?
		guard getifaddrs(&ifaddr) == 0 else { return [] }
		guard let firstAddr = ifaddr else { return [] }
		
		// For each interface ...
		for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
			let flags = Int32(ptr.pointee.ifa_flags)
			var addr = ptr.pointee.ifa_addr.pointee
			
			// Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
			if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
				if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
					
					// Convert interface address to a human readable string:
					var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
					if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
					                nil, socklen_t(0), NI_NUMERICHOST) == 0) {
						let address = String(cString: hostname)
						addresses.append(address)
					}
				}
			}
		}
		
		freeifaddrs(ifaddr)
		return addresses
	}
	
	@IBAction func missedCallCountChanged(_ sender: Any) {
		guard !ignoreMissedCallCountChange else {
			return
		}
		guard let count = Int(missedCallCountField.stringValue) else {
			return
		}
		log(info: "Send missed call count of \(count)")
		do {
			try Server.default.send(notification: MissedCallCountNotification(count: count))
		} catch let error {
			log(error: "\(error)")
		}
	}
	
	@IBAction func callStatusDidChange(_ sender: Any) {
		switch callStatusPopupMenu.indexOfSelectedItem {
		case 0: send(.inactive)
		case 1: send(.outgoing)
		case 2: send(.incoming)
		default: break
		}
	}
	
	@IBAction func wifiConnectionsAction(_ sender: Any) {
		do {
			try Server.default.send(notification: WiFiConnectionsNotification())
		} catch let error {
			log(error: "\(error)")
		}
	}
	
	@IBAction func simLockStatusChanged(_ sender: NSButton) {
		guard let status = buttonToSIMStatus[sender] else {
			return
		}
		
		DataModelManager.shared.set(value: status,
		                            forKey: DataModelKeys.simStatus,
		                            withNotification: false)
		do {
			try Server.default.send(notification: SIMStatusNotification(status))
		} catch let error {
			log(error: "\(error)")
		}

	}
	
	func send(_ callStatus: CallStatus) {
		do {
			try Server.default.send(notification: CallStatusNotification(callStatus))
		} catch let error {
			log(error: "\(error)")
		}
	}
	
	func updateSIMLockStatus() {
//		let status: SIMStatus = DataModelManager.shared.get(forKey: DataModelKeys.simStatus, withDefault: SIMStatus.unlocked)
//		guard let button = simStatusToButton[status] else {
//			return
//		}
//		button.state = NSControl.StateValue.on
	}
	
	@IBAction func autoUnreadMessagesCountAction(_ sender: Any) {
		var unreadMessages = 0
		log(info: "Checking \(MessageManager.shared.conversations.count) conversations")
		MessageManager.shared.conversations.forEach { (conversation) in
			log(info: "Checking \(conversation.messages.count) messages")
			conversation.messages.forEach({ (message) in
				if !message.read {
					log(info: "isUnread: \(message)")
					unreadMessages += 1
				}
			})
		}
		DataModelManager.shared.set(value: unreadMessages,
		                            forKey: DataModelKeys.unreadMessageCount)
	}
	
	@IBAction func unreadMessagesCountAction(_ sender: Any) {
		guard let count = Int(unreadMessageCount.stringValue) else {
			return
		}
		DataModelManager.shared.set(value: count,
		                            forKey: DataModelKeys.unreadMessageCount)
		do {
			try Server.default.send(notification: UnreadMessageCountNotification())
		} catch let error {
			log(error: "\(error)")
		}
	}
	
}
