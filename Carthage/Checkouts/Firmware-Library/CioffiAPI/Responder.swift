//
//  File.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation

public protocol Responder {
    func send(response: ResponseCode, `for`: ResponseType, contents: [String: [String: AnyObject]]?)
}
