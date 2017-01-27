//
// Created by Shane Whitehead on 25/01/2017.
// Copyright (c) 2017 Beam Communications. All rights reserved.
//

import Foundation

public enum GNSSModulePowerStatus: Int {
	case poweredDown = 0
	case poweredUp
}

public enum GNSSFix: Int {
	case notSeen = 0
	case noFix
	case fix2D
	case fix3D
}

struct GNSSLocationCoordinate {
	let coordinate: Double?
	let accuracy: Double?
}

struct GNSSSatellite {
	let name: String
	let count: Int
}

struct GNSSSatelliteGroup {
	let total: Int
	let satellites: [GNSSSatellite]
}

struct GNSSLocationInformation {
	let isActive: Bool
	let powerStatus: GNSSModulePowerStatus
	let fix: GNSSFix
	let time: Date
	let direction: Double?

	let latitude: GNSSLocationCoordinate
	let longitude: GNSSLocationCoordinate
	let altitude: GNSSLocationCoordinate
	let groundSpeed: GNSSLocationCoordinate
	let verticalSpeed: GNSSLocationCoordinate

	let satellites: GNSSSatelliteGroup
}

fileprivate struct GNSSUtilities {

	struct GNSS {
		static let group = "gnss"
		static let active = "active"
		static let powerStatus = "powerStatus"
		static let fix = "fix"
		static let time = "time"
		static let latitude = "latitude"
		static let latitudeAccuracy = "latitudeAccuracy"
		static let longitude = "longitude"
		static let longitudeAccuracy = "longitudeAccuracy"
		static let altitude = "altitude"
		static let altitudeAccuracy = "altitudeAccuracy"
		static let direction = "direction"
		static let groundSpeed = "groundSpeed"
		static let groundSpeedAccuracy = "groundSpeedAccuracy"
		static let verticalSpeed = "verticalSpeed"
		static let verticalSpeedAccuracy = "verticalSpeedAccuracy"

		struct Satellites {
			static let group = "satellites"
			static let used = "satellitesUsed"
			static let entries = "entries"

			struct Satellite {
				static let name = "name"
				static let count = "count"
			}
		}
	}

	static var defaultValue: GNSSLocationInformation {
		let satellites: [GNSSSatellite] = [
				GNSSSatellite(name: "GLONASS", count: 2),
				GNSSSatellite(name: "GPS", count: 8),
				GNSSSatellite(name: "QZSS", count: 1),
				GNSSSatellite(name: "SBAS", count: 1),
		]
		let satelliteGroup: GNSSSatelliteGroup = GNSSSatelliteGroup(total: 12, satellites: satellites)
		let gnssLocationInfo = GNSSLocationInformation(
				isActive: true,
				powerStatus: .poweredUp,
				fix: .fix3D,
				time: Date(),
				direction: 123.321,
				latitude: GNSSLocationCoordinate(coordinate: 132.1234567, accuracy: 10.0),
				longitude: GNSSLocationCoordinate(coordinate: 987.4561235, accuracy: nil),
				altitude: GNSSLocationCoordinate(coordinate: nil, accuracy: 30.0),
				groundSpeed: GNSSLocationCoordinate(coordinate: 98.2, accuracy: 0.5),
				verticalSpeed: GNSSLocationCoordinate(coordinate: 123.8527413, accuracy: 100.250),
				satellites: satelliteGroup)

		return gnssLocationInfo
	}

	static var currentState: [String: Any] {
		let setting: GNSSLocationInformation = DataModelManager.shared.get(forKey: DataModelKeys.gnssLocationInfo,
				withDefault: defaultValue)
		return with(info: setting)
	}

	static func with(info: GNSSLocationInformation) -> [String: Any] {
		var body: [String: Any] = [:]

		var satelliteEntries: [Any] = []
		for satellite in info.satellites.satellites {
			let entry: [String: Any] = [
					GNSSUtilities.GNSS.Satellites.Satellite.name: satellite.name,
					GNSSUtilities.GNSS.Satellites.Satellite.count: satellite.count]
			satelliteEntries.append(entry)
		}

		body[GNSSUtilities.GNSS.group] = [
				GNSSUtilities.GNSS.active: info.isActive ? 1 : 0,
				GNSSUtilities.GNSS.powerStatus: info.powerStatus.rawValue,
				GNSSUtilities.GNSS.fix: info.fix.rawValue,
				GNSSUtilities.GNSS.time: stupidDateFormat.string(from: info.time),
				GNSSUtilities.GNSS.latitude: format(info.latitude.coordinate),
				GNSSUtilities.GNSS.latitudeAccuracy: format(info.latitude.accuracy),
				GNSSUtilities.GNSS.longitude: format(info.longitude.coordinate),
				GNSSUtilities.GNSS.longitudeAccuracy: format(info.longitude.accuracy),
				GNSSUtilities.GNSS.altitude: format(info.altitude.coordinate),
				GNSSUtilities.GNSS.altitudeAccuracy: format(info.altitude.accuracy),
				GNSSUtilities.GNSS.direction: format(info.direction),
				GNSSUtilities.GNSS.groundSpeed: format(info.groundSpeed.coordinate),
				GNSSUtilities.GNSS.groundSpeedAccuracy: format(info.groundSpeed.accuracy),
				GNSSUtilities.GNSS.verticalSpeed: format(info.verticalSpeed.coordinate),
				GNSSUtilities.GNSS.verticalSpeedAccuracy: format(info.verticalSpeed.accuracy),
				GNSSUtilities.GNSS.Satellites.group: [
						GNSSUtilities.GNSS.Satellites.used: info.satellites.total,
						GNSSUtilities.GNSS.Satellites.entries: satelliteEntries
				]
		]
		return body
	}

	static func format(_ value: Double?) -> String {
		guard let value = value else {
			return ""
		}
		return "\(value)"
	}

}

class GNSSLocationInfoFunction: DefaultAPIFunction {

	override func body(preProcessResult: Any?) -> [String: Any] {
		return GNSSUtilities.currentState
	}

}

class GetGNSSLocationDiagnosticInfoFunction: GNSSLocationInfoFunction {

	override init() {
		super.init()

		DataModelManager.shared.set(value: GNSSUtilities.defaultValue,
				forKey: DataModelKeys.gnssSetting)

		self.responseType = .getGNSSLocationInformation
		self.requestType = .getGNSSLocationInformation
	}

}
