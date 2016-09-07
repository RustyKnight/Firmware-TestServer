//
//  Utilities.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 7/09/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation

func synced(lock: Any, closure: () -> ()) {
    defer {
        objc_sync_exit(lock)
    }
    objc_sync_enter(lock)
    closure()
}
