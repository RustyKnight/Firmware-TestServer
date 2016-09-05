//
//  ViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI
import SwiftyJSON

class FunctionView {
    let name: String
    let viewName: String
    
    init(name: String, viewName: String) {
        self.name = name
        self.viewName = viewName
    }
}

class ViewController: NSTabViewController {
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    var functions: [FunctionView] = []
    
    @IBAction func actionWasPerformed(_ sender: NSOutlineView) {
        guard let item = outlineView.item(atRow: sender.clickedRow) as? FunctionView else {
            return
        }
        log(info: "\(item.name)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        functions.append(FunctionView(name: "Server", viewName: "ServerViewController"))
        
//        outlineView.dataSource = self
//        outlineView.delegate = self
        
        _ = RequestHandlerManager.default
        
        do {
            try Server.default.start()
        } catch let error {
            log(error: "\(error)")
        }
        
        for address in getIFAddresses() {
            log(info: address)
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func getIFAddresses() -> [String] {
        var addresses = [String]()
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return [] }
        guard let firstAddr = ifaddr else { return [] }
        
        // For each interface ...
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            var addr = ptr.pointee.ifa_addr.pointee
            
            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
            if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                    
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                        let address = String(cString: hostname)
                        addresses.append(address)
                    }
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return addresses
    }
}

//extension ViewController {
//    
//}
//
//extension ViewController: NSOutlineViewDataSource {
//    
//    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
//        return functions.count
//    }
//    
//    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
//        return functions[index]
//    }
//    
//    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
//        return false
//    }
//}
//
//extension ViewController: NSOutlineViewDelegate {
//    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
//        var view: NSTableCellView?
//        if let function = item as? FunctionView {
//            view = outlineView.make(withIdentifier: "HeaderCell", owner: self) as? NSTableCellView
//            log(info: "\(function.name)")
//            view?.textField?.stringValue = function.name
////            view?.textField?.sizeToFit()
//        }
//        return view
//    }
//}
