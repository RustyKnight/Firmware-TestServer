//
//  APINotification.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 27/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI

protocol APINotification {
    var type: NotificationType {get}
    var payload: [String: [String: AnyObject]] {get}
}

