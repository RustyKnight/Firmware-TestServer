//
//  RequestHandlerRegistry.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import CioffiAPI
import SwiftyJSON

enum RequestRegistryError: ErrorProtocol {
	case missingReuqestType
}

protocol RequestHandler {
	func handle(request: JSON, forResponder: Responder)
}

class RequestHandlerManager {
	static var `default`: RequestHandler {
		return RequestHandlerFactory.registery
	}
}

class RequestHandlerFactory {
	static var registery: RequestHandler = DefaultRequestHandler()
}

class DefaultRequestHandler: RequestHandler {
	
	static let applicationDirectoryName = "CioffiFirmwareServer"
	static let functionsDirectoryName = "functions"
	
	var registry: [RequestType: JSON] = [:]
	
	func supportDirectory() throws -> URL {
		let paths = FileManager.default.urlsForDirectory(.applicationSupportDirectory, inDomains: .userDomainMask)
		var path = paths.first!
		try path.appendPathComponent(DefaultRequestHandler.applicationDirectoryName)
		return path
	}
	
	func functionsDirectory() throws -> URL {
		var path = try supportDirectory()
		try path.appendPathComponent(DefaultRequestHandler.functionsDirectoryName)
		return path
	}
	
	init() {
		loadFunctions()
	}
	
	func loadFunctions() {
		do {
			let path = try functionsDirectory()
			var contents = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: [], options: [])
			contents = contents.filter{$0.pathExtension == "json"}
			for file in contents {
				try loadFunction(from: file)
			}
		} catch let error {
			log(error: "\(error)")
		}
	}
	
	func loadFunction(from: URL) throws {
		let data = try Data(contentsOf: from)
		let json = JSON(data: data)
		guard let type = json["request"]["header"]["type"].int else {
			throw RequestRegistryError.missingReuqestType
		}
		let requestType = RequestType.for(type)
		registry[requestType] = json
	}
	
	func handle(request: JSON, forResponder responder: Responder) {
		
		guard let typeCode = request["header"]["type"].int else {
			return
		}
		
		let requestType = RequestType.for(typeCode)
		log(info: "requestType: \(requestType)")
		guard let handler = registry[requestType] else {
			log(info: "No handler for request \(requestType)")
			responder.sendUn
			return
		}
	}
}
