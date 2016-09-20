//
//  WiFiConfigurationViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 20/09/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa

class WiFiConfigurationViewController: NSViewController {
	
	@IBOutlet weak var passphraseField: NSTextField!
	@IBOutlet weak var ssidField: NSTextField!
	@IBOutlet weak var channelField: NSComboBox!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		channelField.addItems(withObjectValues:
			[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
		)
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(WiFiConfigurationViewController.configurationDidChange),
		                                       name: NSNotification.Name.init(rawValue: wifiConfigurationKey),
		                                       object: nil)
		
		updateConfiguration()
	}
	
	override func viewDidDisappear() {
		super.viewDidDisappear()
	}
	
	func configurationDidChange() {
		DispatchQueue.main.async {
			self.updateConfiguration()
		}
	}
	
	func updateConfiguration() {
		let config: WiFiConfiguration  = DataModelManager.shared.get(forKey: wifiConfigurationKey, withDefault: defaultWifiConfiguration)
		ssidField.stringValue = config.ssid
		channelField.selectItem(withObjectValue: config.channel)
		guard let passphrase = config.passphrase else {
			passphraseField.stringValue = ""
			return
		}
		passphraseField.stringValue = passphrase
	}
	
}
