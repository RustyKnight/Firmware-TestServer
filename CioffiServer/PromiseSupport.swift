//
//  PromiseSupport.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 18/10/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import PromiseKit

struct PromiseUtilities {
	
	static let shared = PromiseUtilities()
	
	func with(delay: TimeInterval) -> Promise<Void> {
    return Promise<Void> {(fulfill, fail) in
			DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: {
				fulfill(())
			})
		}
	}
	
}
