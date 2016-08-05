//
//  ServerViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 3/08/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class ServerViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func stateDidChange(_ sender: NSButton) {
        if sender.state == NSOnState {
            do {
                try Server.default.start()
            } catch let error {
                log(error: "\(error)")
            }
        } else {
            Server.default.stop()
        }
    }
    
}
