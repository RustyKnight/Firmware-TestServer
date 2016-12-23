//
//  VersionViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa

class VersionViewController: NSViewController {
    @IBOutlet weak var majorVersion: NSTextField!
    @IBOutlet weak var minorVersion: NSTextFieldCell!
    @IBOutlet weak var patchVersion: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func stringValue(forKey key: DataModelKey, withDefault defaultValue: String) -> String {
        let value = DataModelManager.shared.get(forKey: key, withDefault: defaultValue)
        return value
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        majorVersion.stringValue = stringValue(forKey: DataModelKeys.majorVersion, withDefault: "1")
        minorVersion.stringValue = stringValue(forKey: DataModelKeys.minorVersion, withDefault: "1")
        patchVersion.stringValue = stringValue(forKey: DataModelKeys.patchVersion, withDefault: "1")
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
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
}
