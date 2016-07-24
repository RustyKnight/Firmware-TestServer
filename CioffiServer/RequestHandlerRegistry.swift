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
import Fuzi

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
		let doc = try Fuzi.XMLDocument(data: data)
		
//		<cioffi type="function" name="GetVersion">
//		<request>
//		<header>
//		<type>1</type>
//		<version>1</version>
//		</header>
//		</request>
//		<response>
//		<header>
//		<type>2</type>
//		<version>1</version>
//		<version>0</version>
//		</header>
//		<group name="firmware">
//		<variable name="majorVersion" property="majorVersion" type="Int"/>
//		<variable name="minorVersion" property="minorVersion" type="Int"/>
//		<variable name="patchVersion" property="patchVersion" type="Int"/>
//		</group>
//		</response>
//		</cioffi>
		
		let json = JSON(data: data)
		log(info: "Load from \(from)")
		guard let type = json["request"]["header"]["type"].int else {
			throw RequestRegistryError.missingReuqestType
		}
		let requestType = RequestType.for(type)
		registry[requestType] = json
	}
	
	func handle(request: JSON, forResponder responder: Responder) {
		// Do we have a type
		guard let typeCode = request["header"]["type"].int else {
			return
		}
		// Look up the script
		let requestType = RequestType.for(typeCode)
		log(info: "requestType: \(requestType)")
		guard let json = registry[requestType] else {
			log(info: "No handler for request \(requestType)")
			responder.sendUnsupportedAPIResponse(for: requestType)
			return
		}
		
		var response: [String: [String: AnyObject]] = [:]
		let responseScript = json["response"]
		
		response["header"] = [:]
		response["header"]?["type"] = responseScript["header"]["type"].intValue
		response["header"]?["version"] = responseScript["header"]["version"].intValue
		response["header"]?["result"] = responseScript["header"]["result"].intValue
		
		log(info: "group = \(responseScript["group"].count)")
		log(info: "group = \(responseScript["group"].array)")
		
		for group in responseScript["group"].arrayValue {
			let groupName = group["name"].stringValue
			log(info: "groupName = \(groupName)")
			for value in group[groupName].arrayValue {
				let valueName = value["name"].stringValue
				let valueType = value["type"].stringValue
				let valueValue = value["value"].stringValue
				log(info: "valueName = \(valueName)")
				log(info: "valueType = \(valueType)")
				log(info: "valueValue = \(valueValue)")
			}
		}
	}
}
