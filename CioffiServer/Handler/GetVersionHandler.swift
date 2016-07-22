//
//  GetVersionHandler.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON
import CioffiAPI

class GetVersionHandler: RequestHandler {
    func handle(request: JSON, `for` responder: Responder) {
        var version: [String: AnyObject] = [:]
        version["majorVersion"] = 1
        version["minorVersion"] = 1
        version["patchVersion"] = 1
        
        let contents: [String: [String: AnyObject]] = [
            "firmware": version
        ]
        
        responder.send(response: .success, for: .getVersion, contents: contents)
    }
}
