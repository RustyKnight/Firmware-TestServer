//
//  GroupViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 12/08/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class GroupView {
    let description: String
    let identifier: String
    
    init(description: String, identifier: String) {
        self.description = description
        self.identifier = identifier
    }
}

protocol GroupViewDelegate {
    func groupView(_ controller: GroupViewController, groupSelected: GroupView)
}

class GroupViewController: NSViewController {

    @IBOutlet weak var outlineView: NSOutlineView!
    
    var delegate: GroupViewDelegate?
    
    let groups: [GroupView] = [
        GroupView(description: "Server", identifier: "Server"),
        GroupView(description: "Version", identifier: "Version")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        outlineView.dataSource = self
        outlineView.delegate = self
        
        outlineView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
    }
    
    var selectedGroup: GroupView? {
        guard outlineView.selectedRow >= 0 && outlineView.selectedRow < groups.count else {
            log(info: "Bad selectedRow \(outlineView.selectedRow)")
            return nil
        }
        return groups[outlineView.selectedRow]
    }
    
}

extension GroupViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let view = outlineView.make(withIdentifier: "DataCell", owner: self) as? NSTableCellView else {
            log(info: "Bad cell")
            return nil
        }
        guard let group = item as? GroupView else {
            log(info: "Bad text")
            return nil
        }
        view.textField?.stringValue = group.description
        return view
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let source = notification.object as? NSOutlineView else {
            return
        }
        let selectedIndex = source.selectedRow
        guard let group = source.item(atRow: selectedIndex) as? GroupView else {
            return
        }
        
        delegate?.groupView(self, groupSelected: group)
    }
}

extension GroupViewController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        log(info: "count = \(groups.count)")
        return groups.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        log(info: "value @ \(index) = \(groups[index])")
        return groups[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
}
