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
	case missingType
    case invalidType
    case missingName
    case missingRequest
    case missingResponse
    case missingHeaderType
    case missingHeaderVersion
    case missingGroupName
    case missingVariableName
    case missingVariableProperty
    case missingVariableType
    case missingVariableValue
    case missingAllowedValueName
    case missingAllowedValue
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
    
    var functions: [APIFunction] = []
    var variables: [String: String] = [:]
	
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
			contents = contents.filter{$0.pathExtension == "xml"}
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
        guard let type = doc.root?.attr("type") else {
            throw RequestRegistryError.missingType
        }
        guard type == "function" else {
            throw RequestRegistryError.invalidType
        }
        guard let name = doc.root?.attr("name") else {
            throw RequestRegistryError.missingName
        }
        
        log(info: "name = \(name); type = \(type)")
        
        guard let requestNode = doc.first(xpath: "/cioffi/request") else {
            throw RequestRegistryError.missingRequest
        }
        guard let responseNode = doc.first(xpath: "/cioffi/response") else {
            throw RequestRegistryError.missingResponse
        }
        
        let requestHeader = try parseHeader(from: requestNode)
        let responseHeader = try parseHeader(from: responseNode)

        let request = DefaultRequest(header: requestHeader)
        let groups = try parseGroups(from: responseNode)
        let response = DefaultResponse(header: responseHeader, groups: groups)
        
        let apiFunction = DefaultAPIFunction(name: name, request: request, response: response)
        
        functions.append(apiFunction)

	}
    
    func parseGroups(from node: Fuzi.XMLElement) throws -> [Group] {
        let groupNodes = node.xpath("group")
        var groups: [Group] = []
        for groupNode in groupNodes {
            groups.append(try parseGroup(from: groupNode))
        }
        
        return groups
    }
    
    func parseGroup(from groupNode: Fuzi.XMLElement) throws -> Group {
        guard let groupName = groupNode.attr("name") else {
            throw RequestRegistryError.missingGroupName
        }
        var group = DefaultGroup(name: groupName)
        let propertyNodes = groupNode.xpath("property")
        for propertyNode in propertyNodes {
            group.append(property: try parseProperty(from: propertyNode))
        }
        
        return group
    }
    
    func parseProperty(from propertyNode: Fuzi.XMLElement) throws -> Property {
        guard let name = propertyNode.attr("name") else {
            throw RequestRegistryError.missingVariableName
        }
        guard let variable = propertyNode.attr("variable") else {
            throw RequestRegistryError.missingVariableProperty
        }
        guard let type = propertyNode.attr("type") else {
            throw RequestRegistryError.missingVariableType
        }
        guard let defaultValue = propertyNode.attr("default") else {
            throw RequestRegistryError.missingVariableValue
        }
        
        variables[variable] = defaultValue
        var property = DefaultProperty(name: name, variable: variable, type: type, defaultValue: defaultValue)
        let allowedNodes = propertyNode.xpath("allowed")
        for allowedNode in allowedNodes {
            property.append(allowedValue: try parseAllowedValue(from: allowedNode))
        }
        
        return property
    }
    
    func parseAllowedValue(from allowedNode: Fuzi.XMLElement) throws -> AllowedValue {
        guard let valueName = allowedNode.attr("name") else {
            throw RequestRegistryError.missingAllowedValueName
        }
        guard let value = allowedNode.attr("value") else {
            throw RequestRegistryError.missingAllowedValue
        }
        return DefaultAllowedValue(name: valueName, value: value)
    }
    
    func parseHeader(from: Fuzi.XMLElement) throws -> Header {
        guard let type = from.int(forXpath: "header/type") else {
            throw RequestRegistryError.missingHeaderType
        }
        guard let version = from.int(forXpath: "header/version") else {
            throw RequestRegistryError.missingHeaderVersion
        }
        
        return DefaultHeader(type: type, version: version)
    }
    
    func function(forRequest type: RequestType) -> APIFunction? {
        return functions.filter { (function) -> Bool in
            return function.request.header.type == type.rawValue
        }.first
    }
	
    func value(forProperty property: Property) -> AnyObject {
        let value = variables[property.variable]
        switch property.type {
        case "String": return value ?? ""
        case "Int": return Int(value ?? "0") ?? 0
        default:
            break
        }
        
        return "unknown type \(property.type) for \(value)"
    }
    
	func handle(request: JSON, forResponder responder: Responder) {
		// Do we have a type
		guard let typeCode = request["header"]["type"].int else {
			return
		}
		// Look up the script
		let requestType = RequestType.for(typeCode)
		log(info: "requestType: \(requestType)")
        guard let function = function(forRequest: requestType) else {
            log(info: "No handler for request \(requestType)")
            responder.sendUnsupportedAPIResponse(for: requestType)
            return
        }
        log(info: "Respond with \(function.response.header.type)")

		var response: [String: [String: AnyObject]] = [:]
        response["header"] = [
            "type": function.response.header.type,
            "version": function.response.header.version
            // Support errors?
        ]
        
        for group in function.response.groups {
            var properties: [String: AnyObject] = [:]
            for property in group.properties {
                properties[property.name] = value(forProperty: property)
            }
            response[group.name] = properties
        }
        
        let responseType = ResponseType.for(function.response.header.type)
        responder.send(response: .success,
                       for: responseType,
                       contents: response)
//		let responseScript = json["response"]
//		
//		response["header"] = [:]
//		response["header"]?["type"] = responseScript["header"]["type"].intValue
//		response["header"]?["version"] = responseScript["header"]["version"].intValue
//		response["header"]?["result"] = responseScript["header"]["result"].intValue
//		
//		log(info: "group = \(responseScript["group"].count)")
//		log(info: "group = \(responseScript["group"].array)")
//		
//		for group in responseScript["group"].arrayValue {
//			let groupName = group["name"].stringValue
//			log(info: "groupName = \(groupName)")
//			for value in group[groupName].arrayValue {
//				let valueName = value["name"].stringValue
//				let valueType = value["type"].stringValue
//				let valueValue = value["value"].stringValue
//				log(info: "valueName = \(valueName)")
//				log(info: "valueType = \(valueType)")
//				log(info: "valueValue = \(valueValue)")
//			}
//		}
	}
}

protocol Header {
    var type: Int {get}
    var version: Int {get}
}

struct DefaultHeader: Header, CustomStringConvertible {
    let type: Int
    let version: Int
    
    var description: String {
        return "Header type: \(type); version = \(version)"
    }
}

func ==(lhs: Header, rhs: Header) -> Bool {
    return lhs.type == rhs.type &&
        lhs.version == rhs.version
}

protocol Request {
    var header: Header {get}
}

protocol Response {
    var header: Header {get}
    var groups: [Group] {get}
}

struct DefaultRequest: Request, CustomStringConvertible {
    let header: Header
    
    var description: String {
        return "Request \(header)"
    }
}

func ==(lhs: Request, rhs: Request) -> Bool {
    return lhs.header == rhs.header
}

struct DefaultResponse: Response, CustomStringConvertible {
    let header: Header
    let groups: [Group]
    
    var description: String {
        return "Response \(header)"
    }
}

func ==(lhs: Response, rhs: Response) -> Bool {
    return lhs.header == rhs.header &&
        lhs.groups == rhs.groups
}

protocol AllowedValue {
    var name: String {get}
    var value: String {get}
}

func ==(lhs: AllowedValue, rhs: AllowedValue) -> Bool {
    return lhs.name == rhs.name &&
        lhs.value == rhs.value
}

func ==(lhs: [AllowedValue], rhs: [AllowedValue]) -> Bool {
    if lhs.count != rhs.count {
        return false
    }
    for index in 0..<lhs.count {
        if !(lhs[index] == rhs[index]) {
            return false
        }
    }
    return true
}


struct DefaultAllowedValue: AllowedValue {
    let name: String
    let value: String
}

protocol Property {
    var name: String {get}
    var variable: String {get}
    var type: String {get}

    var defaultValue: String {get}
    var allowedValues: [AllowedValue] {get}
}

func ==(lhs: Property, rhs: Property) -> Bool {
    return lhs.name == rhs.name &&
        lhs.variable == rhs.variable &&
        lhs.type == rhs.type &&
        lhs.defaultValue == rhs.defaultValue &&
        lhs.allowedValues == rhs.allowedValues
}

func ==(lhs: [Property], rhs: [Property]) -> Bool {
    if lhs.count != rhs.count {
        return false
    }
    for index in 0..<lhs.count {
        if !(lhs[index] == rhs[index]) {
            return false
        }
    }
    return true
}

protocol Group {
    var name: String {get}
    var properties: [Property] {get}
}

func ==(lhs: Group, rhs: Group) -> Bool {
    return lhs.name == rhs.name &&
    lhs.properties == rhs.properties
}

func ==(lhs: [Group], rhs: [Group]) -> Bool {
    if lhs.count != rhs.count {
        return false
    }
    for index in 0..<lhs.count {
        if !(lhs[index] == rhs[index]) {
            return false
        }
    }
    return true
}

struct DefaultGroup: Group {
    let name: String
    var properties: [Property]
    
    init(name: String) {
        self.name = name
        properties = []
    }
    
    mutating func append(property: Property) {
        properties.append(property)
    }
}

struct DefaultProperty: Property {
    var name: String
    var variable: String
    var type: String
    
    var defaultValue: String
    var allowedValues: [AllowedValue]
    
    init(name: String, variable: String, type: String, defaultValue: String) {
        self.name = name
        self.variable = variable
        self.type = type
        self.defaultValue = defaultValue
        allowedValues = []
    }
    
    mutating func append(allowedValue: AllowedValue) {
        allowedValues.append(allowedValue)
    }
}

protocol APIFunction {
    var name: String {get}
    var request: Request {get}
    var response: Response {get}
}

struct DefaultAPIFunction: APIFunction {
    let name: String
    let request: Request
    let response: Response
}

extension Fuzi.XMLDocument {
    func first(xpath path: String, from parent: Fuzi.XMLElement? = nil) -> Fuzi.XMLElement? {
        var from = root
        if parent != nil {
            from = parent
        }
        guard let parent = from else {
            return nil
        }
        
        return parent.firstChild(xpath: path)
    }
    
    func int(forXpath xpath: String, from parent: Fuzi.XMLElement? = nil) -> Int? {
        guard let node = first(xpath: xpath, from: parent) else {
            return nil
        }
        return Int(node.stringValue)
    }
}

extension Fuzi.XMLElement {
    func first(xpath path: String) -> Fuzi.XMLElement? {
        return firstChild(xpath: path)
    }
    
    func int(forXpath xpath: String) -> Int? {
        guard let node = first(xpath: xpath) else {
            return nil
        }
        return Int(node.stringValue)
    }
    
}
