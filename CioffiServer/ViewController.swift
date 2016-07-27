//
//  ViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class ViewController: NSTabViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = RequestHandlerManager.default
        
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
        let notification = ShuttingDownNotification(type: .powerButtonPressed)
        do {
            try Server.default.send(notification: notification)
        } catch let error {
            log(error: "\(error)")
        }
//        var payload: [String: [String: AnyObject]] = [:]
//        payload["alert"] = [
//            "type": 0
//        ]
    }
}
