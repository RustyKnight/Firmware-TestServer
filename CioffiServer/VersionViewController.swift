//
//  VersionViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa

class VersionViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
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
