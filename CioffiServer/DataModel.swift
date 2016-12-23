//
//  DataModel.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI

struct DataModelKeys {
	static let unreadMessageCount = DefaultDataModelKey(key: "Key.unreadMessageCount")
	static let audibleAlertOption = DefaultDataModelKey(key: "Key.AudibleAlertOption")

	static let automaticSAPAState = DefaultDataModelKey(key: "sapa.automaticState")
	static let sapaState = DefaultDataModelKey(key: "sapa.state")

	static let networkMode = DefaultDataModelKey(key: "networkModeKey")

 	static let serviceProvider = DefaultDataModelKey(key: "serviceProvider")

	static let broadbandDataActiveMode = DefaultDataModelKey(key: "broadbandDataActiveMode")

	// Represents the active mode status, which is seperate from the settings
	static let satelliteBroadbandDataActiveUplinkSpeed = DefaultDataModelKey(key: "satelliteBroadbandDataActiveUplinkSpeed") // What is the "active" speed
	static let satelliteBroadbandDataActiveDownlinkSpeed = DefaultDataModelKey(key: "satelliteBroadbandDataActiveDownlinkSpeed") // What is the "active" speed

	static let satelliteBroadbandDataUplinkSpeed = DefaultDataModelKey(key: "satelliteBroadbandDataUplinkSpeed")
	static let satelliteBroadbandDataDownlinkSpeed = DefaultDataModelKey(key: "satelliteBroadbandDataDownlinkSpeed")

	static let satelliteBroadbandDataMode = DefaultDataModelKey(key: "broadbandDataMode")

	static let adminRestricition = DefaultDataModelKey(key: "adminRestricition")
	static let smsRestricition = DefaultDataModelKey(key: "smsRestricition")
	static let dataRestricition = DefaultDataModelKey(key: "dataRestricition")
	static let callRestricition = DefaultDataModelKey(key: "callRestricition")

	static let adminPassword = DefaultDataModelKey(key: "adminPassword")
	static let smsPassword = DefaultDataModelKey(key: "smsPassword")
	static let dataPassword = DefaultDataModelKey(key: "dataPassword")
	static let callPassword = DefaultDataModelKey(key: "callPassword")

	static let adminLocked = DefaultDataModelKey(key: "adminLocked")
	static let smsLocked = DefaultDataModelKey(key: "smsLocked")
	static let dataLocked = DefaultDataModelKey(key: "dataLocked")
	static let callLocked = DefaultDataModelKey(key: "callLocked")


	static let accessRestrictionKeys: [AccessRestricition: AccessRestricitionKeySet] = [
			.admin: AccessRestricitionKeySet(enabledKey: adminRestricition,
					restrictedKey: adminLocked,
					passwordKey: adminPassword),
			.data: AccessRestricitionKeySet(enabledKey: dataRestricition,
					restrictedKey: dataLocked,
					passwordKey: dataPassword),
			.call: AccessRestricitionKeySet(enabledKey: callRestricition,
					restrictedKey: callLocked,
					passwordKey: callPassword),
			.sms: AccessRestricitionKeySet(enabledKey: smsRestricition,
					restrictedKey: smsLocked,
					passwordKey: smsPassword),
	]


	static let majorVersion = DefaultDataModelKey(key: "majorVersion")
	static let minorVersion = DefaultDataModelKey(key: "minorVersion")
	static let patchVersion = DefaultDataModelKey(key: "patchVersion")

	static let signalStrength = DefaultDataModelKey(key: "signalStrength")

	static let cellularNetworkMode = DefaultDataModelKey(key: "CellularNetworkModeMode")


	static let currentSatelliteNetworkRegistrationStatus = DefaultDataModelKey(key: "NetworkRegistrationStatus.satellite.current")
	static let currentCellularNetworkRegistrationStatus = DefaultDataModelKey(key: "NetworkRegistrationStatus.cellular.current")

	static let targetSatelliteNetworkRegistrationStatus = DefaultDataModelKey(key: "NetworkRegistrationStatus.satellite.target")
	static let targetCellularNetworkRegistrationStatus = DefaultDataModelKey(key: "NetworkRegistrationStatus.cellular.target")

	static let missedCallCount = DefaultDataModelKey(key: "Key.missedCallCount")

	static let batteryCharge = DefaultDataModelKey(key: "batteryCharge")
	static let batteryStatus = DefaultDataModelKey(key: "batteryStatus")
	static let batteryVoltage = DefaultDataModelKey(key: "batteryVoltage")
	static let batteryPresent = DefaultDataModelKey(key: "batteryPresent")

	static let simStatus = DefaultDataModelKey(key: "Key.SIMStatus")
	static let simPIN = DefaultDataModelKey(key: "Key.SIMPIN")

	static let wifiConfiguration = DefaultDataModelKey(key: "wifi.config")

	static let currentModemModule = DefaultDataModelKey(key: "currentModemModuleKey")

	static let satelliteServiceMode = DefaultDataModelKey(key: "satelliteServiceMode.mode")

	static let systemTemperature = DefaultDataModelKey(key: "systemTemperature")

	static let outbound = DefaultDataModelKey(key: "Firewall.outbound")
	static let inbound = DefaultDataModelKey(key: "Firewall.inbound")

	static let ipAddressConfiguration = DefaultDataModelKey(key: "Key.ipAddressConfiguration")

	static let qosKey = DefaultDataModelKey(key: "Key.qos")

	static let dmzKey = DefaultDataModelKey(key: "Key.dmz")

	static let portForwarding = DefaultDataModelKey(key: "Key.PortForwarding")

	static let MACAddressFiltering = DefaultDataModelKey(key: "Key.MACAddressFiltering")

	static let emergencyNumber = DefaultDataModelKey(key: "Key.EmergencyNumber")

	static let cellularNetworkRoaming = DefaultDataModelKey(key: "Key.CellularNetworkRoaming")

	static let callStatus = DefaultDataModelKey(key: "Key.CallStatus")

	static let dataUsage = DefaultDataModelKey(key: "Key.DataUsage")

	static let gnssSetting = DefaultDataModelKey(key: "Key.gnnsSetting")

	static let hardwareDiagnosticInfo = DefaultDataModelKey(key: "Key.hardwareDiagnosticInfo")

	static let postResult = DefaultDataModelKey(key: "Key.POSTResult")

}

protocol DataModelKey {
	var key: String { get }
	var notification: NSNotification.Name { get }
}

struct DefaultDataModelKey: DataModelKey {
	let key: String
	var notification: NSNotification.Name {
		return NSNotification.Name.init(rawValue: key)
	}
}

protocol DataModel {
	func get(forKey: DataModelKey) -> Any?
	func set(value: Any, forKey: DataModelKey)

	func set(value: Any, forKey: DataModelKey, withNotification: Bool)

	func get<R: Any>(forKey key:DataModelKey, withDefault defaultValue: R) -> R
}

struct DataModelManager {
	static let shared: DataModel = DefaultDataModel()
}

class DefaultDataModel: DataModel {
	var data: [AnyHashable: Any] = [:]

	func get<R: Any>(forKey key: DataModelKey, withDefault defaultValue: R) -> R {
		guard let value = get(forKey: key) as? R else {
			return defaultValue
		}
		return value
	}

	func get(forKey: DataModelKey) -> Any? {
		var value: Any? = nil
		synced(lock: self) {
			value = self.data[forKey.key]
	//            log(info: "Get \(forKey) is \(value)")
		}
		return value
	}

	func set(value: Any, forKey: DataModelKey) {
		set(value: value, forKey: forKey, withNotification: true)
	}

	func set(value: Any, forKey: DataModelKey, withNotification: Bool = true) {
		synced(lock: self) {
	//            log(info: "Set \(forKey) to \(value)")
			data[forKey.key] = value
			if withNotification {
				NotificationCenter.default.post(name: forKey.notification,
						object: value)
			}
		}
	}

}
