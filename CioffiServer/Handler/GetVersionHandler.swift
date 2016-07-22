//
//  GetVersionHandler.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON

class GetVersionHandler: RequestHandler {
    func handle(request: JSON, `for` client: Client) {
        var version: [String: AnyObject] = [:]
        version["majorVersion"] = 1
        version["minorVersion"] = 1
        version["patchVersion"] = 1
        
        let contents: [String: [String: AnyObject]] = [
            "firmware": version
        ]
        
        client.send(response: .success, for: .getVersion, contents: contents)
    }
}
