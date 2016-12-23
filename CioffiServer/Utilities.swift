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

private var shutdownNetworkRegistrationStatusSwitcher: ChainedModeSwitcher<NetworkRegistrationStatus>?
private var startupNetworkRegistrationStatusSwitcher: ChainedModeSwitcher<NetworkRegistrationStatus>?

enum ModemModule: Int {
	case satellite = 0
	case cellular = 1
	case unknown = -1

	var networkMode: NetworkMode {
		switch self {
			case .cellular: return .cellular
			case .satellite: return .satellite
			default: return .smartSwitch
		}
	}
	
	func makeCurrent(withLifeCycle: Bool = false) {
		let current = ModemModule.current
		if self != current {
			
			if let shutdownNetworkRegistrationStatusSwitcher = shutdownNetworkRegistrationStatusSwitcher {
				shutdownNetworkRegistrationStatusSwitcher.cancel()
			}
			if let startupNetworkRegistrationStatusSwitcher = startupNetworkRegistrationStatusSwitcher {
				startupNetworkRegistrationStatusSwitcher.cancel()
			}
			
			DataModelManager.shared.set(value: self, forKey: DataModelKeys.currentModemModule)
			if withLifeCycle {

				from(modem: current)
				to(modem: self)
				
			}
		}
	}
	
	func isPowered(status value: NetworkRegistrationStatus) -> Bool {
		return status(value, within: [
			NetworkRegistrationStatus.poweredOn,
			NetworkRegistrationStatus.poweringOn,
			NetworkRegistrationStatus.registering,
			NetworkRegistrationStatus.registeredRoaming,
			NetworkRegistrationStatus.registrationDenied,
			NetworkRegistrationStatus.registeredHomeNetwork,
		])
	}

	func isUnpowered(status value: NetworkRegistrationStatus) -> Bool {
		return status(value, within: [
			NetworkRegistrationStatus.poweredOff,
			NetworkRegistrationStatus.poweringOff,
			])
	}
	
	func status(_ status: NetworkRegistrationStatus, within states: [NetworkRegistrationStatus]) -> Bool {
		return states.filter({ (check) -> Bool in
			return check == status
		}).count > 0
	}
	
	func steps(`for` modem: ModemModule) -> [AnyModeLink<NetworkRegistrationStatus>] {
		let currentState = DataModelManager.shared.get(forKey: currentNetworkRegistrationStateKeys[modem]!,
		                                               withDefault: NetworkRegistrationStatus.poweredOff)
		let targetState = DataModelManager.shared.get(forKey: targetNetworkRegistrationStateKeys[modem]!,
		                                              withDefault: NetworkRegistrationStatus.poweredOff)
		log(info: "modem = \(modem); currentState = \(currentState); targetState = \(targetState)")
		return steps(for: modem, from: currentState, to: targetState)
	}
	
	func steps(`for` modem: ModemModule,
	           from currentState: NetworkRegistrationStatus,
	           to targetState: NetworkRegistrationStatus = .poweredOff) -> [AnyModeLink<NetworkRegistrationStatus>] {
		var steps: [AnyModeLink<NetworkRegistrationStatus>] = []
		if isPowered(status: currentState) && isUnpowered(status: targetState) {
			steps.append(AnyModeLink<NetworkRegistrationStatus>(value: NetworkRegistrationStatus.poweringOff,
			                                                    delay: 0,
			                                                    notification: NetworkRegistrationStatusNotification(module: modem)))
			steps.append(AnyModeLink<NetworkRegistrationStatus>(value: NetworkRegistrationStatus.poweredOff,
			                                                    delay: 10,
			                                                    notification: NetworkRegistrationStatusNotification(module: modem)))
		} else if isPowered(status: targetState) && isUnpowered(status: currentState) {
			steps.append(AnyModeLink<NetworkRegistrationStatus>(value: NetworkRegistrationStatus.poweringOn,
			                                                    delay: 0,
			                                                    notification: NetworkRegistrationStatusNotification(module: modem)))
			steps.append(AnyModeLink<NetworkRegistrationStatus>(value: NetworkRegistrationStatus.poweredOn,
			                                                    delay: 2,
			                                                    notification: NetworkRegistrationStatusNotification(module: modem)))
			steps.append(AnyModeLink<NetworkRegistrationStatus>(value: NetworkRegistrationStatus.registering,
			                                                    delay: 2,
			                                                    notification: NetworkRegistrationStatusNotification(module: modem)))
			if targetState != NetworkRegistrationStatus.registering {
				steps.append(AnyModeLink<NetworkRegistrationStatus>(value: targetState,
				                                                    delay: 2,
				                                                    notification: NetworkRegistrationStatusNotification(module: modem)))
			}
		} else {
			steps.append(AnyModeLink<NetworkRegistrationStatus>(value: targetState,
			                                                    delay: 10,
			                                                    notification: NetworkRegistrationStatusNotification(module: modem)))
		}
		return steps
	}
	
	func from(modem current: ModemModule) {
		let currentState = DataModelManager.shared.get(forKey: currentNetworkRegistrationStateKeys[current]!,
		                                               withDefault: NetworkRegistrationStatus.poweredOff)
		
		let shutdownSteps = steps(for: current, from: currentState)
		
		shutdownNetworkRegistrationStatusSwitcher = ChainedModeSwitcher(key: currentNetworkRegistrationStateKeys[current]!,
		                                                                defaultValue: .unknown,
		                                                                links: shutdownSteps)
		shutdownNetworkRegistrationStatusSwitcher?.start(completion: {
			shutdownNetworkRegistrationStatusSwitcher = nil
		})
	}
	
	func to(modem: ModemModule) {
		startupNetworkRegistrationStatusSwitcher = ChainedModeSwitcher(key: currentNetworkRegistrationStateKeys[modem]!,
		                                                               defaultValue: .unknown,
		                                                               links: steps(for: modem))
		startupNetworkRegistrationStatusSwitcher?.start(completion: {
			startupNetworkRegistrationStatusSwitcher = nil
		})
	}
	
	func currentNetworkRegistration(`for` modem: ModemModule) -> NetworkRegistrationStatus {
		guard let key = currentNetworkRegistrationStateKeys[modem] else {
			return NetworkRegistrationStatus.unknown
		}
		
		return DataModelManager.shared.get(forKey: key, withDefault: NetworkRegistrationStatus.poweredOff)
	}
	
	func targetNetworkRegistration(`for` modem: ModemModule) -> NetworkRegistrationStatus {
		guard let key = targetNetworkRegistrationStateKeys[modem] else {
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
		let current = DataModelManager.shared.get(forKey: DataModelKeys.currentModemModule, withDefault: ModemModule.unknown)
		//        log(info: "current = \(current)")
		return current
	}
}

protocol ModemModular {
	var modemModule: ModemModule? {get set}
}
