//
//  RequestHandler.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

protocol RequestHandler {
    func handle(request: JSON, `for`: Responder)
}
