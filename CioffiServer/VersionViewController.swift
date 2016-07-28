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
    
    func stringValue(forKey key: String, withDefault defaultValue: String) -> String {
        guard let value = DataModelManager.shared.get(forKey: key, withDefault: defaultValue) as? String else {
            return defaultValue
        }
        return value
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        majorVersion.stringValue = stringValue(forKey: GetVersionFunction.majorVersionKey, withDefault: "1")
        minorVersion.stringValue = stringValue(forKey: GetVersionFunction.minorVersionKey, withDefault: "1")
        patchVersion.stringValue = stringValue(forKey: GetVersionFunction.patchVersionKey, withDefault: "1")
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
    }
    
    @IBAction func majorFieldChanged(_ sender: NSTextField) {
        DataModelManager.shared.set(value: sender.integerValue,
                                    forKey: GetVersionFunction.majorVersionKey)
    }
    @IBAction func minorFieldChanged(_ sender: NSTextField) {
        DataModelManager.shared.set(value: sender.integerValue,
                                    forKey: GetVersionFunction.minorVersionKey)
    }
    @IBAction func patchFieldChanged(_ sender: NSTextField) {
        DataModelManager.shared.set(value: sender.integerValue,
                                    forKey: GetVersionFunction.patchVersionKey)
    }
}
