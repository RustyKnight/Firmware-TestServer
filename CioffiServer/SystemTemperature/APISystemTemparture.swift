//
//  APISystemTemparture.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 21/09/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

let systemTemperatureKey = "systemTemperature"

protocol DualTemperatureSensor {
	var sensorA: String {get set}
	var sensorB: String {get set}
}

protocol AntennaTemperature: DualTemperatureSensor {
}

protocol PCBTemperature: DualTemperatureSensor {
}

struct DefaultDualTemperatureSensor: DualTemperatureSensor, AntennaTemperature, PCBTemperature {
	var sensorA: String
	var sensorB: String
}

protocol SystemTemperature {
	var antenna: AntennaTemperature {get set}
	var pcb: PCBTemperature {get set}
	var battery: String {get set}
}

struct DefaultSystemTemperature: SystemTemperature {
	var antenna: AntennaTemperature
	var pcb: PCBTemperature
	var battery: String
}

let defaultSystemTemperature: SystemTemperature = DefaultSystemTemperature(antenna: DefaultDualTemperatureSensor(sensorA: "", sensorB: "15.1"),
                                                                           pcb: DefaultDualTemperatureSensor(sensorA: "-10.0", sensorB: "-15.1"),
                                                                           battery: "5503.85")

struct SystemTemperatureUtilities {
	static var body: [String: Any] {
		var body: [String: Any] = [:]
		let temp: SystemTemperature  = DataModelManager.shared.get(forKey: systemTemperatureKey, withDefault: defaultSystemTemperature)
		body["temperature"] = [
			"pcbA": temp.pcb.sensorA,
			"pcbB": temp.pcb.sensorB,
			"antennaA": temp.antenna.sensorA,
			"antennaB": temp.antenna.sensorB,
			"battery": temp.battery
		]
		return body
	}
}

class GetSystemTemperature: DefaultAPIFunction {
	override init() {
		super.init()
		
		responseType = .getSystemTemperature
		requestType = .getSystemTemperature
		
		DataModelManager.shared.set(value: defaultSystemTemperature, forKey: systemTemperatureKey)
	}
	
	override func body() -> [String : Any] {
		return SystemTemperatureUtilities.body
	}
}
