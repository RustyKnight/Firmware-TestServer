//
//  Server.swift
//  TestServer
//
//  Created by Shane Whitehead on 30/06/2016.
//  Copyright © 2016 KaiZen. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import SwiftyJSON
import CioffiAPI

class Server: NSObject {
	
	static var readTimeout: TimeInterval = 30
	
	static let dataKey = "Server.data"
	static let errorKey = "Server.error"
	
	static let dataWrittenNotification: NSNotification.Name = NSNotification.Name("Server.dataWritten")
	static let dataReadNotification: NSNotification.Name = NSNotification.Name("Server.dataRead")
	static let clientDisconnectedNotification: NSNotification.Name = NSNotification.Name("Server.clientDisconnecetd")
	static let clientConnectedNotification: NSNotification.Name = NSNotification.Name("Server.clientConnecetd")
	
	static let `default` = Server()
	
	internal let socket: GCDAsyncSocket
	
	internal var clientSockets: [GCDAsyncSocket] = []
	internal var clientDelegates: [GCDAsyncSocket: ClientSocketDelegate] = [:]
	
	internal var connectionId: Int = 0
	
	override init() {
		socket = GCDAsyncSocket()
		super.init()
		socket.delegateQueue = DispatchQueue(label: "server-socket")
		socket.delegate = self
	}
	
	func start() throws {
		try socket.accept(onPort: 51234)
		log(info: "Server started")
	}
	
	func stop() {
		for clientSocket in clientSockets {
			clientSocket.delegate = nil
			clientSocket.disconnect()
		}
		socket.disconnect()
		log(info: "Server stopped")
	}
	
	func send(notification: NotificationType, payload: [String: [String: AnyObject]]) throws {
		
		let data = try ProtocolUtils.dataFor(notification: notification, payload: payload)
		
		for socket in clientSockets {
			socket.write(data, withTimeout: 30.0, tag: 0)
		}
	}
	
	func wasDiconnected(client: GCDAsyncSocket) {
		guard let index = clientSockets.index(of: client) else {
			log(info: "Unknown client was disconnected")
			return
		}
		clientDelegates[client] = nil
		client.delegate = nil
		clientSockets.remove(at: index)
	}
	
}

extension Server: GCDAsyncSocketDelegate {
	
	func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
		log(info: "\(newSocket.localHost)")
		
		let clientSocket = newSocket
		objc_sync_enter(self)
		defer {
			objc_sync_exit(self)
		}
		
		let delegate = ClientSocketDelegate()
		connectionId += 1
		clientSocket.delegate = delegate
		
		clientSockets.append(clientSocket)
		clientDelegates[clientSocket] = delegate
		
		// Start the waiting game :)
		delegate.start(with: clientSocket)
		
		NotificationCenter.default.post(name: Server.clientConnectedNotification,
		                                object: Server.default)
	}
	
	func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
		log(warning: "Server didRead data?")
	}
	
	func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: NSError?) {
		log(warning: "Server didDisconnect with \(err)")
	}
	
}

class ClientSocketDelegate: NSObject, GCDAsyncSocketDelegate {
	
	static let headerTag = 100
	static let bodyTag = 101
	
	static let responseTag = 200
	
	//    internal let connectionId: Int
	
	var header: Data?
	//
	//    init(connectionId: Int) {
	//        self.connectionId = connectionId
	//    }
	
	func start(with socket: GCDAsyncSocket) {
		readHeader(from: socket)
		//
		//        var message = ProtocolUtils.getHeader(responseType: .getVersion, code: .success)
		//        var firmware: [String: [String: AnyObject]] = [:]
		//        firmware["firmware"] = [
		//            "majorVersion": 1,
		//            "minorVersion": 1,
		//            "patchVersion": 1]
		//
		//        message += firmware
		//        do {
		//            let data = try ProtocolUtils.dataFor(payload: message)
		//            socket.write(data, withTimeout: Server.readTimeout, tag: ClientSocketDelegate.responseTag)
		//        } catch let error {
		//            log(error: "\(error)")
		//        }
	}
	
	func readHeader(from sock : GCDAsyncSocket) {
		read(from: sock,
		     toLength: ProtocolUtils.headerLength,
		     tag: ClientSocketDelegate.headerTag)
	}
	
	func readBody(from sock : GCDAsyncSocket, toLength length: UInt) {
		read(from: sock,
		     toLength: length,
		     tag: ClientSocketDelegate.bodyTag)
	}
	
	func read(from sock : GCDAsyncSocket, toLength length: UInt, tag: Int) {
		sock.readData(toLength: length,
		              withTimeout: -1,
		              tag: tag)
	}
	
	func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
		if tag == ClientSocketDelegate.headerTag {
			header = data
			let bodyLength = ProtocolUtils.getBodyLength(from: data)
			readBody(from: sock, toLength: bodyLength)
		} else if tag == ClientSocketDelegate.bodyTag {
			defer {
				header = nil
			}
			if let header = header {
				do {
					log(info: "Process new request")
					try ProtocolUtils.processRequest(header: header,
					                                 body: data,
					                                 for: SocketClient(socket: sock))
				} catch let error {
					log(error: "\(error)")
					// Send error response
				}
			}
			readHeader(from: sock)
		}
	}
	
	func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
	}
	
	func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: NSError?) {
		log(info: "Client didDisconnect with \(err)")
		var userInfo: [NSObject:AnyObject] = [:]
		if let error = err {
			userInfo = [Server.dataKey:error]
		}
		Server.default.wasDiconnected(client: sock)
		NotificationCenter.default.post(name: Server.clientDisconnectedNotification,
		                                object: Server.default,
		                                userInfo: userInfo)
	}
	
}

class SocketClient: Responder {
	let socket: GCDAsyncSocket
	
	init(socket: GCDAsyncSocket) {
		self.socket = socket
	}
	
	func sendUnsupportedAPIResponse(`for` type: RequestType) {
		sendUnsupportedAPIResponse(for: type.rawValue)
	}
	
	func sendUnsupportedAPIResponse(`for` code: Int) {
		let message = ProtocolUtils.header(forType: code, result: ResponseCode.unsupportedAPIType.rawValue)
		do {
			let data = try ProtocolUtils.dataFor(payload: message)
			socket.write(data, withTimeout: Server.readTimeout, tag: ClientSocketDelegate.responseTag)
		} catch let error {
			log(error: "\(error)")
		}
	}
	
	func send(response code: ResponseCode, `for` response: ResponseType, contents: [String: [String: AnyObject]]? = nil) {		
		var message = ProtocolUtils.header(forResponse: response, code: code)
		if let contents = contents {
			message += contents
		}
		do {
			let data = try ProtocolUtils.dataFor(payload: message)
			socket.write(data, withTimeout: Server.readTimeout, tag: ClientSocketDelegate.responseTag)
		} catch let error {
			log(error: "\(error)")
			send(response: .failure, for: response)
		}
	}
}
