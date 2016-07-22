//
//  ViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try Server.default.start()
        } catch let error {
            log(error: "\(error)")
        }
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func shutdownNotification(_ sender: AnyObject) {
        var payload: [String: [String: AnyObject]] = [:]
        payload["alert"] = [
            "type": 0
        ]
        do {
            try Server.default.send(notification: .shutdownNotification, payload: payload)
        } catch let error {
            log(error: "\(error)")
        }
    }
}

