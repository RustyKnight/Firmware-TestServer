//
//  SplitGroupViewController.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 12/08/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Cocoa
import CioffiAPI

class SplitGroupViewController: NSSplitViewController {

    var tabViewController: NSTabViewController!
    var groupViewController: GroupViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let tabViewController = splitViewItems[1].viewController as? NSTabViewController else {
            fatalError("Unable to find tab view controller")
        }
        guard let groupViewController = splitViewItems[0].viewController as? GroupViewController else {
            fatalError("Unable to find tab view controller")
        }
        self.tabViewController = tabViewController
        self.groupViewController = groupViewController
        groupViewController.delegate = self
        
        guard let group = groupViewController.selectedGroup else {
            return
        }
        select(group: group)
    }
    
    func tabViewItem(`for` identifier: String) -> NSTabViewItem? {
        let items = tabViewController.tabViewItems

        return items.first { (item: NSTabViewItem) -> Bool in
            guard let id = item.identifier as? String else {
                return false
            }
            return id == identifier
        }
    }
    
    func index(`for` tab: NSTabViewItem) -> Int? {
        return tabViewController.tabViewItems.index(of: tab)
    }
    
    func index(`for` identifier: String) -> Int? {
        guard let tabViewItem = tabViewItem(for: identifier) else {
            return nil
        }
        return index(for: tabViewItem)
    }
    
}

extension SplitGroupViewController: GroupViewDelegate {
    
    func groupView(_ controller: GroupViewController, groupSelected group: GroupView) {
        select(group: group)
    }
    
    func select(group: GroupView) {
        guard let index = index(for: group.identifier) else {
            return
        }
        tabViewController.selectedTabViewItemIndex = index
    }
    
}
