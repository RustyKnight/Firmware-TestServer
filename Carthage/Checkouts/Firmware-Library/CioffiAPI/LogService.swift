//
//  LogService.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation

public class LogService {
    public static var `default`: LogService = LogService()
    
    public enum Level {
        case info
        case warn
        case error
    }
    
    public func log(level: Level, message: String, file: String = #file, function: String = #function, line: Int = #line) {
        var fileName = file
        if let url = URL(string: file) {
            
            let name = url.lastPathComponent
            let ext = url.pathExtension
            
            fileName = name.replacingOccurrences(of: ext, with: "")
            fileName = fileName.characters.split(separator: ".").flatMap(String.init).first!
        }
        
        var value = ""
        switch level {
        case .info: value += "I"
        case .warn: value += "W"
        case .error: value += "E"
        }
        value += "|"
        value += "[\(fileName)]"
        value += "[\(function)"
        value += "@\(line.description)]"
        value += " \(message)"
        
        print(value)
    }
    
    public func log(info message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }
    
    public func log(warning message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warn, message: message, file: file, function: function, line: line)
    }
    
    public func log(error message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }
}

public func log(info: String, file: String = #file, function: String = #function, line: Int = #line) {
    LogService.default.log(info: info, file: file, function: function, line: line)
}

public func log(warning: String, file: String = #file, function: String = #function, line: Int = #line) {
    LogService.default.log(warning: warning, file: file, function: function, line: line)
}

public func log(error: String, file: String = #file, function: String = #function, line: Int = #line) {
    LogService.default.log(error: error, file: file, function: function, line: line)
}
