//
//  WifiConfiguration.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 20/09/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

let wifiConfigurationKey = "wifi.config"

protocol WiFiConfiguration {
	var ssid: String {get}
	var channel: Int {get}
	var restricted: Bool {get}
	var passphrase: String? {get}
}

struct DefaultWifiConfiguration: WiFiConfiguration {
	let ssid: String
	let channel: Int
	var restricted: Bool {
		return passphrase != nil
	}
	let passphrase: String?
}

let defaultWifiConfiguration: DefaultWifiConfiguration = DefaultWifiConfiguration(ssid: "awsome-wifi", channel: 1, passphrase: nil)

struct WiFiConfigurationUtilities {
	static var body: [String: Any] {
		var body: [String: Any] = [:]
		let config: WiFiConfiguration  = DataModelManager.shared.get(forKey: wifiConfigurationKey, withDefault: defaultWifiConfiguration)
		body["wifi"] = [
			"ssid": config.ssid,
			"channel": config.channel,
			"auth": config.restricted
		]
		return body
	}
}

class GetWiFiConfiguration: DefaultAPIFunction {
	override init() {
		super.init()
		
		responseType = .getWifiConfiguration
		requestType = .getWifiConfiguration
		
		DataModelManager.shared.set(value: defaultWifiConfiguration, forKey: wifiConfigurationKey)
	}
	
	override func body(preProcessResult: Any? = nil) -> [String : Any] {
		return WiFiConfigurationUtilities.body
	}
}

class SetWiFiConfiguration: GetWiFiConfiguration {
	override init() {
		super.init()
		requestType = .setWifiConfiguration
		responseType = .setWifiConfiguration
	}
	
	override func preProcess(request: JSON) -> PreProcessResult {
		guard let ssid = request["wifi"]["ssid"].string, let channel = request["wifi"]["channel"].int else {
			log(warning: "Missing ssid and/or channel")
			return createResponse(type: .failed)
		}
		let passphrase: String? = request["wifi"]["passphrase"].string
		DataModelManager.shared.set(value: DefaultWifiConfiguration(ssid: ssid,
		                                                            channel: channel,
		                                                            passphrase: passphrase),
		                            forKey: wifiConfigurationKey)
		return createResponse(type: .success)
	}
}
