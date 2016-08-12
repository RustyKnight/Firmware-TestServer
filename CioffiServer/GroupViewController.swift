//
//  GroupViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 12/08/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class GroupViewController: NSViewController {

    @IBOutlet weak var outlineView: NSOutlineView!
    
    let groups: [String] = [
        "Common",
        "Satellite",
        "Cellular"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        outlineView.dataSource = self
        outlineView.delegate = self
    }
    
}

extension GroupViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        guard let view = outlineView.make(withIdentifier: "DataCell", owner: self) as? NSTableCellView else {
            log(info: "Bad cell")
            return nil
        }
        guard let text = item as? String else {
            log(info: "Bad text")
            return nil
        }
        view.textField?.stringValue = text
        return view
    }
}

extension GroupViewController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        log(info: "count = \(groups.count)")
        return groups.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        log(info: "value @ \(index) = \(groups[index])")
        return groups[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        return false
    }
}
