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

    @IBOutlet weak var tableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = RequestHandlerManager.default
        
        do {
            try Server.default.start()
        } catch let error {
            log(error: "\(error)")
        }
        
        tableView.delegate = self
        tableView.dataSource = self
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

extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 1
    }
    
}

extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.make(withIdentifier: "SliderCell", owner: nil) as? SliderCell else {
            return nil
        }
        
        cell.configure(min: 0, max: 5, current: 0)
        
        return cell
    }
}

