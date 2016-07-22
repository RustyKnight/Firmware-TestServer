//
//  ProtocolUtilities.swift
//  CioffiServer
//
//  Created by Shane Whitehead on 22/07/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import Foundation
import SwiftyJSON

public enum ProtocolError: ErrorProtocol {
    case jsonEncodingError
    case dataEncodingError
    case requestDecodingError
    case invalidCRC
    case missingRequestType
}

@objc public class ProtocolUtils: NSObject {
    
    public static let headerLength: UInt = 8
    public static let headValue = "\(Utils.hexStringtoAscii(hexString: "A5A5"))"
    public static let flagValue = "\(Utils.hexStringtoAscii(hexString: "0000"))"
    public static let defaultCRC = "\(Utils.hexStringtoAscii(hexString: "0000"))"
    
    public static var apiVersion: Int = 1
    
    /**
     Gets the request header for a given request type
     - Parameters:
     - requestType: Request Type
     - Returns: Request header
     */
    public static func getHeader(requestType: RequestType) -> [String: [String: AnyObject]] {
        return getHeader(type: requestType.rawValue)
    }
    
    public static func getHeader(notificationType: NotificationType) -> [String: [String: AnyObject]] {
        return getHeader(type: notificationType.rawValue)
    }

    public static func getHeader(responseType: ResponseType, code: ResponseCode) -> [String: [String: AnyObject]] {
        return getHeader(type: responseType.rawValue, result: code.rawValue)
    }
    
    public static func getHeader(responseType: ResponseType, result: Int) -> [String: [String: AnyObject]] {
        return getHeader(type: responseType.rawValue, result: result)
    }
    
    /**
     Gets the request header for a given request type
     - Parameters:
     - requestType: Request Type
     - Returns: Request header
     */
    public static func getHeader(type: Int, result: Int? = nil) -> [String: [String: AnyObject]] {
        var header: [String: [String: AnyObject]] = ["header": ["version": apiVersion, "type" : type]]
        if let result = result {
            header["header"]?["result"] = result
        }
        return header
    }
    
    /**
     Returns a protocol message for a given message body
     - Parameters:
     - messageBody: Message body
     - Returns: A protocol message
     */
    public class func getProtocolMessage(messageBody: String) -> String {
        var protocolMessage = ""
        
        // Calculate the size for the message body
        let sizeHexValue = Utils.hexStringFromInt(value: messageBody.characters.count)
        let sizeValue = Utils.hexStringtoAscii(hexString: sizeHexValue)
        
        // Base initial CRC from the default CRC
        let crcHeader = getProtocolMessage(size: sizeValue, crc: defaultCRC, messageBody: messageBody)
        
        if let crc = crcHeader.data(using: String.Encoding.isoLatin1, allowLossyConversion: false)?.crcCCITT {
            // Calculate CRC
            let hexCrc = Utils.hexStringFromInt(value: Int(crc))
            let hexStr = Utils.hexStringtoAscii(hexString: hexCrc)
            protocolMessage = getProtocolMessage(size: sizeValue, crc: hexStr, messageBody: messageBody)
        }
        
        log(info: "Protocol message \(protocolMessage)")
        
        return protocolMessage
    }
    
    /**
     Returns a protocol message
     // HEAD|SIZE|FLAGS|CRC|BODY
     - Parameters:
     - size: Message size
     - crc: CRC
     - messageBody: Message body
     - Returns: A protocol header
     */
    public class func getProtocolMessage(size: String, crc: String, messageBody: String) -> String {
        return "\(headValue)\(size)\(flagValue)\(crc)\(messageBody)"
    }
    
    public class func dataFor(notification: NotificationType, payload: [String: [String: AnyObject]]) throws -> Data {
        var header = ProtocolUtils.getHeader(notificationType: notification)
        header += payload
        return try dataFor(payload: header)
    }
    
    public class func dataFor(payload: [String: [String: AnyObject]]) throws -> Data {
        return try dataFor(json: JSON(payload))
    }
    
    public class func dataFor(json: JSON) throws -> Data {
        guard let jsonString = json.rawString(String.Encoding.isoLatin1, options: []) else {
            throw ProtocolError.jsonEncodingError
        }
        
        return try dataFor(string: jsonString)
    }
    
    public class func dataFor(string: String) throws -> Data {
        let encoded = getProtocolMessage(messageBody: string)
        guard let data = encoded.data(using: String.Encoding.isoLatin1, allowLossyConversion: false) else {
            throw ProtocolError.dataEncodingError
        }
        return data
    } 
    
    public class func getBodyLength(from data: Data) -> UInt {
        let buffer = UnsafeMutableBufferPointer<UInt8>(
            start: UnsafeMutablePointer<UInt8>(allocatingCapacity: data.count),
            count: data.count)
        let _ = data.copyBytes(to: buffer)
        let headerBytes = Array(buffer)
        return getBodyLength(from: headerBytes)
    }
    
    public class func getBodyLength(from headerBytes: [UInt8]) -> UInt {
        return (UInt(headerBytes[2]) * 256) + UInt(headerBytes[3])
    }

    public class func validCRC(fromHeader headerData: Data, body bodyData: Data) -> Bool {
        
        // Compute CRC
        var bytes = Array(UnsafeBufferPointer(
            start: UnsafePointer<UInt8>((headerData as NSData).bytes),
            count: (headerData as NSData).length))
        
        let expectedCrc = getExpectedCRC(from: bytes)
        
        // Reset the crc bytes to compute the new crc value
        bytes[6] = 0
        bytes[7] = 0
        
        var crcData = Data(bytes: bytes)
        crcData.append(bodyData)
        
        let currentCrc = UInt(crcData.crcCCITT)
        
        return currentCrc == expectedCrc
    }
    
    public class func getExpectedCRC(from bytes: [UInt8]) -> UInt {
        return (UInt(bytes[6]) * 256) + UInt(bytes[7])
    }
}

public struct Utils {
    
    /**
     Returns a hex string for a given Int
     - Parameters:
     - value: Int value
     - Returns: Hex representation of the Int value
     */
    public static func hexStringFromInt(value: Int) -> String {
        return String(format: "%04x", value).uppercased()
    }
    
    /**
     Returns a Ascii string for the given hex string
     - Parameters:
     - hexString: Int value
     - pattern: Pattern to match (Default (0x)?([0-9a-f]{2}) )
     - Returns: Ascii value of hex
     */
    public static func hexStringtoAscii(hexString: String,
                                 pattern: String = "(0x)?([0-9a-f]{2})") -> String {
        guard let regex = try? RegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return ""
        }
        
        let nsString = hexString as NSString
        let matches = regex.matches(in: hexString, options: [], range: NSRange(location: 0, length: nsString.length))
        let characters = matches.map {
            Character(UnicodeScalar(UInt32(nsString.substring(with: $0.range(at: 2)), radix: 16)!))
        }
        
        return String(characters)
    }
}

public let SEED: UInt16 = 0x0000

public let crcCCITTLookupTable: [UInt16] = [
    0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50A5, 0x60C6, 0x70E7, 0x8108,
    0x9129, 0xA14A, 0xB16B, 0xC18C, 0xD1AD, 0xE1CE, 0xF1EF, 0x1231, 0x0210,
    0x3273, 0x2252, 0x52B5, 0x4294, 0x72F7, 0x62D6, 0x9339, 0x8318, 0xB37B,
    0xA35A, 0xD3BD, 0xC39C, 0xF3FF, 0xE3DE, 0x2462, 0x3443, 0x0420, 0x1401,
    0x64E6, 0x74C7, 0x44A4, 0x5485, 0xA56A, 0xB54B, 0x8528, 0x9509, 0xE5EE,
    0xF5CF, 0xC5AC, 0xD58D, 0x3653, 0x2672, 0x1611, 0x0630, 0x76D7, 0x66F6,
    0x5695, 0x46B4, 0xB75B, 0xA77A, 0x9719, 0x8738, 0xF7DF, 0xE7FE, 0xD79D,
    0xC7BC, 0x48C4, 0x58E5, 0x6886, 0x78A7, 0x0840, 0x1861, 0x2802, 0x3823,
    0xC9CC, 0xD9ED, 0xE98E, 0xF9AF, 0x8948, 0x9969, 0xA90A, 0xB92B, 0x5AF5,
    0x4AD4, 0x7AB7, 0x6A96, 0x1A71, 0x0A50, 0x3A33, 0x2A12, 0xDBFD, 0xCBDC,
    0xFBBF, 0xEB9E, 0x9B79, 0x8B58, 0xBB3B, 0xAB1A, 0x6CA6, 0x7C87, 0x4CE4,
    0x5CC5, 0x2C22, 0x3C03, 0x0C60, 0x1C41, 0xEDAE, 0xFD8F, 0xCDEC, 0xDDCD,
    0xAD2A, 0xBD0B, 0x8D68, 0x9D49, 0x7E97, 0x6EB6, 0x5ED5, 0x4EF4, 0x3E13,
    0x2E32, 0x1E51, 0x0E70, 0xFF9F, 0xEFBE, 0xDFDD, 0xCFFC, 0xBF1B, 0xAF3A,
    0x9F59, 0x8F78, 0x9188, 0x81A9, 0xB1CA, 0xA1EB, 0xD10C, 0xC12D, 0xF14E,
    0xE16F, 0x1080, 0x00A1, 0x30C2, 0x20E3, 0x5004, 0x4025, 0x7046, 0x6067,
    0x83B9, 0x9398, 0xA3FB, 0xB3DA, 0xC33D, 0xD31C, 0xE37F, 0xF35E, 0x02B1,
    0x1290, 0x22F3, 0x32D2, 0x4235, 0x5214, 0x6277, 0x7256, 0xB5EA, 0xA5CB,
    0x95A8, 0x8589, 0xF56E, 0xE54F, 0xD52C, 0xC50D, 0x34E2, 0x24C3, 0x14A0,
    0x0481, 0x7466, 0x6447, 0x5424, 0x4405, 0xA7DB, 0xB7FA, 0x8799, 0x97B8,
    0xE75F, 0xF77E, 0xC71D, 0xD73C, 0x26D3, 0x36F2, 0x0691, 0x16B0, 0x6657,
    0x7676, 0x4615, 0x5634, 0xD94C, 0xC96D, 0xF90E, 0xE92F, 0x99C8, 0x89E9,
    0xB98A, 0xA9AB, 0x5844, 0x4865, 0x7806, 0x6827, 0x18C0, 0x08E1, 0x3882,
    0x28A3, 0xCB7D, 0xDB5C, 0xEB3F, 0xFB1E, 0x8BF9, 0x9BD8, 0xABBB, 0xBB9A,
    0x4A75, 0x5A54, 0x6A37, 0x7A16, 0x0AF1, 0x1AD0, 0x2AB3, 0x3A92, 0xFD2E,
    0xED0F, 0xDD6C, 0xCD4D, 0xBDAA, 0xAD8B, 0x9DE8, 0x8DC9, 0x7C26, 0x6C07,
    0x5C64, 0x4C45, 0x3CA2, 0x2C83, 0x1CE0, 0x0CC1, 0xEF1F, 0xFF3E, 0xCF5D,
    0xDF7C, 0xAF9B, 0xBFBA, 0x8FD9, 0x9FF8, 0x6E17, 0x7E36, 0x4E55, 0x5E74,
    0x2E93, 0x3EB2, 0x0ED1, 0x1EF0,
]

public func calculateCRCCCITT(seed: UInt16, data: NSData) -> UInt16 {
    let bytePointer = UnsafePointer<UInt8>(data.bytes)
    let bytes = UnsafeBufferPointer<UInt8>(start: bytePointer, count: data.length)
    var sum = seed
    
    for byte in bytes {
        let index = Int((sum >> 8) ^ UInt16(byte))
        sum = crcCCITTLookupTable[index] ^ (sum << 8)
    }
    
    return sum
}

public extension Data {
    var crcCCITT: UInt16 {
        return calculateCRCCCITT(seed: SEED, data: self)
    }
}
