//
// Created by Shane Whitehead on 19/12/2016.
// Copyright (c) 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import PromiseKit
import CioffiAPI

public enum HardwareModem: Int  {
	case cellular = 1
	case satellite
}

public struct TemperatureHardwareInfo {
	public let antennaSensorA: String
	public let antennaSensorB: String
	public let pcbSensorA: String
	public let pcbSensorB: String
	public let battery: String
}


public struct TransceiverHardwareInfo {
	public let hardwareVersion: String
	public let softwareVersion: String
}

public struct TransmitterHardwareInfo {
	public let type: HardwareModem
	public let imei: String
	public let transceiver: TransceiverHardwareInfo
}

public struct DeviceHardwareInfo {
	public let serialNumber: String
	public let hardwareRevisionNumber: String
	public let firmwareRevisionNumber: String
	public let temperature: TemperatureHardwareInfo
	public let simICCIDNumber: String
}

public struct HardwareDiagnosticInfo {
	public var device: DeviceHardwareInfo
	public let modem: TransmitterHardwareInfo
}


fileprivate struct Key {

	struct Device {
		static let group = "device"
		static let serialNumber = "serialNumber"
		static let hardwareRevisionNumber = "hardwareRevisionNumber"
		static let firmwareRevisionNumber = "firmwareRevisionNumber"
		static let simICCIDNumber = "simICCIDNumber"
		struct Temperature {
			static let group = "temperature"
			static let antennaSensorA = "antennaSensorA"
			static let antennaSensorB = "antennaSensorB"
			static let pcbSensorA = "pcbSensorA"
			static let pcbSensorB = "pcbSensorB"
			static let battery = "battery"
		}
	}

	static let modem = "modem"

	struct Transmitter {
		static let type = "type"
		static let imei = "imei"
		struct Transceiver {
			static let group = "transceiver"
			static let hardwareVersion = "hardwareVersion"
			static let softwareVersion = "softwareVersion"
		}
	}

	static let defaultValue = HardwareDiagnosticInfo(
			device: DeviceHardwareInfo(
					serialNumber: "123.456",
					hardwareRevisionNumber: "789.321",
					firmwareRevisionNumber: "654.987",
					temperature: TemperatureHardwareInfo(
							antennaSensorA: "38",
							antennaSensorB: "52",
							pcbSensorA: "18",
							pcbSensorB: "15",
							battery: "35"),
					simICCIDNumber: "123456789"),
			modem: TransmitterHardwareInfo(
					type: .cellular,
					imei: "135.256.789",
					transceiver: TransceiverHardwareInfo(
							hardwareVersion: "852.147",
							softwareVersion: "963.258")))

	static var currentState: [String: Any] {
		let setting: HardwareDiagnosticInfo = DataModelManager.shared.get(forKey: DataModelKeys.hardwareDiagnosticInfo,
				withDefault: defaultValue)
		return with(setting: setting)
	}

	static func with(setting: HardwareDiagnosticInfo) -> [String: Any] {
		var body: [String: Any] = [:]

		body[Key.Device.group] = [
				Key.Device.serialNumber: setting.device.serialNumber,
				Key.Device.hardwareRevisionNumber: setting.device.hardwareRevisionNumber,
				Key.Device.firmwareRevisionNumber: setting.device.firmwareRevisionNumber,
				Key.Device.simICCIDNumber: setting.device.simICCIDNumber,
				Key.Device.Temperature.group: [
					Key.Device.Temperature.antennaSensorA: setting.device.temperature.antennaSensorA,
					Key.Device.Temperature.antennaSensorB: setting.device.temperature.antennaSensorB,
					Key.Device.Temperature.pcbSensorA: setting.device.temperature.pcbSensorA,
					Key.Device.Temperature.pcbSensorB: setting.device.temperature.pcbSensorB,
					Key.Device.Temperature.battery: setting.device.temperature.battery,
				]
		]

		body[Key.modem] = [
				Key.Transmitter.type: setting.modem.type.rawValue,
				Key.Transmitter.imei: setting.modem.imei,
				Key.Transmitter.Transceiver.group: [
						Key.Transmitter.Transceiver.hardwareVersion: setting.modem.transceiver.hardwareVersion,
						Key.Transmitter.Transceiver.softwareVersion: setting.modem.transceiver.softwareVersion,
				]
		]
		return body
	}

}

class HardwareDiagnosticInfoFunction: DefaultAPIFunction {

	override func body(preProcessResult: Any?) -> [String: Any] {
		return Key.currentState
	}

}

class GetHardwareDiagnosticInfoFunction: HardwareDiagnosticInfoFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: Key.defaultValue,
				forKey: DataModelKeys.gnssSetting)

		self.responseType = .getHardwareDiagnosticInfo
		self.requestType = .getHardwareDiagnosticInfo
	}

}
