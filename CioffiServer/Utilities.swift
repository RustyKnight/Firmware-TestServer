//
//  Utilities.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 7/09/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI

func synced(lock: Any, closure: () -> ()) {
	defer {
		objc_sync_exit(lock)
	}
	objc_sync_enter(lock)
	closure()
}

let currentModemModuleKey = "currentModemModuleKey"

private var shutdownNetworkRegistrationStatusSwitcher: ChainedModeSwitcher<NetworkRegistrationStatus>?
private var startupNetworkRegistrationStatusSwitcher: ChainedModeSwitcher<NetworkRegistrationStatus>?

enum ModemModule: Int {
	case satellite = 0
	case cellular = 1
	case unknown = -1
	
	func makeCurrent(withLifeCycle: Bool = false) {
		let current = ModemModule.current
		if self != current {
			
			if let shutdownNetworkRegistrationStatusSwitcher = shutdownNetworkRegistrationStatusSwitcher {
				shutdownNetworkRegistrationStatusSwitcher.cancel()
			}
			if let startupNetworkRegistrationStatusSwitcher = startupNetworkRegistrationStatusSwitcher {
				startupNetworkRegistrationStatusSwitcher.cancel()
			}
			
			DataModelManager.shared.set(value: self, forKey: currentModemModuleKey)
			if withLifeCycle {
				let shutdownSteps: [AnyModeLink<NetworkRegistrationStatus>] = [
					AnyModeLink<NetworkRegistrationStatus>(value: NetworkRegistrationStatus.poweringOff,
					                                       delay: 0,
					                                       notification: NetworkRegistrationStatusNotification(module: current)),
					AnyModeLink<NetworkRegistrationStatus>(value: NetworkRegistrationStatus.poweredOff,
					                                       delay: 10,
					                                       notification: NetworkRegistrationStatusNotification(module: current))
				]
				let targetState = DataModelManager.shared.get(forKey: modemModuleKeys[self]!,
				                                              withDefault: NetworkRegistrationStatus.registeredHomeNetwork)
				let startupSteps: [AnyModeLink<NetworkRegistrationStatus>] = [
					AnyModeLink<NetworkRegistrationStatus>(value: NetworkRegistrationStatus.poweringOn,
					                                       delay: 0,
					                                       notification: NetworkRegistrationStatusNotification(module: self)),
					AnyModeLink<NetworkRegistrationStatus>(value: NetworkRegistrationStatus.poweredOn,
					                                       delay: 2,
					                                       notification: NetworkRegistrationStatusNotification(module: self)),
					AnyModeLink<NetworkRegistrationStatus>(value: NetworkRegistrationStatus.registering,
					                                       delay: 2,
					                                       notification: NetworkRegistrationStatusNotification(module: self)),
					AnyModeLink<NetworkRegistrationStatus>(value: targetState,
					                                       delay: 2,
					                                       notification: NetworkRegistrationStatusNotification(module: self)),
					]
				
				if networkRegistration(for: current) != .poweredOff {
					shutdownNetworkRegistrationStatusSwitcher = ChainedModeSwitcher(key: modemModuleKeys[current]!,
					                                                                defaultValue: .unknown,
					                                                                links: shutdownSteps)
					shutdownNetworkRegistrationStatusSwitcher?.start(completion: {
						shutdownNetworkRegistrationStatusSwitcher = nil
					})
				}
				let newState = networkRegistration(for: self)
				if newState != .poweredOff {
					startupNetworkRegistrationStatusSwitcher = ChainedModeSwitcher(key: modemModuleKeys[self]!,
					                                                               defaultValue: .unknown,
					                                                               links: startupSteps)
					startupNetworkRegistrationStatusSwitcher?.start(completion: {
						startupNetworkRegistrationStatusSwitcher = nil
					})
				}
			}
		}
	}
	
	func networkRegistration(`for` modem: ModemModule) -> NetworkRegistrationStatus {
		guard let key = modemModuleKeys[modem] else {
			return NetworkRegistrationStatus.unknown
		}
		
		return DataModelManager.shared.get(forKey: key, withDefault: NetworkRegistrationStatus.poweredOff)
	}
	
	static func isCurrent(_ value: ModemModule?) -> Bool {
		guard let value = value else {
			return false
		}
		return value.isCurrent
	}
	
	var isCurrent: Bool {
		guard self != .unknown else {
			return false
		}
		let current = ModemModule.current
		guard current != .unknown else {
			return false
		}
		return current == self
	}
	
	static var current: ModemModule {
		let current = DataModelManager.shared.get(forKey: currentModemModuleKey, withDefault: ModemModule.unknown)
		//        log(info: "current = \(current)")
		return current
	}
}

protocol ModemModular {
	var modemModule: ModemModule? {get set}
}
