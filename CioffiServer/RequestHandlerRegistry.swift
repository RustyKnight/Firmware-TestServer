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

enum RequestRegistryError: Error {
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
	
	var functions: [RequestType: APIFunction] = [:]
	
	init() {
		functions[.getVersion] = GetVersionFunction()
		functions[.getNetworkMode] = GetNetworkModeFunction()
		functions[.setNetworkMode] = SetNetworkModeFunction()
		
		functions[.getAccessRestricitions] = GetAccessRestricitionsFunction()
		functions[.unlockAccessRestriction] = UnlockAccessRestricitionFunction()
		functions[.stopAccess] = StopAccessFunction()
		
		functions[.getNetworkRegistrationStatus] = GetNetworkRegistrationStatusFunction()
		functions[.getSignalStrength] = GetSignalStrengthFunction()
		
		functions[.getBatteryStatus] = GetBatteryStatusFunction()
		functions[.getServiceProviderName] = GetServiceProvideFunction()
		
		functions[.getSatelliteServiceMode] = GetSatelliteServiceModeFunction()
		functions[.setSatelliteServiceMode] = SetSatelliteServiceModeFunction()
		
		functions[.getSatelliteBroadbandDataIPMode] = GetSatelliteBroadbandDataIPMode()
		functions[.setSatelliteBroadbandDataIPMode] = SetSatelliteBroadbandDataIPMode()
		
		functions[.getSatelliteBroadbandStreamingSpeed] = GetSatelliteBroadbandDataSpeed()
		functions[.setSatelliteBroadbandStreamingSpeed] = SetSatelliteBroadbandDataSpeed()
		
		functions[.getBroadbandDataModeStatus] = GetBroadbandDataModeStatus()
		functions[.startStopBroadbandData] = StartStopBroadbandDataMode()
		
		functions[.getAutomaticSAPAStatus] = GetAutomaticSAPAStatusFunction()
		functions[.setAutomaticSAPAStatus] = SetAutomaticSAPAStatusFunction()
		
		functions[.getSAPAStatus] = GetSAPAStatusFunction()
		functions[.startStopSAPA] = StartStopSAPAFunction()
		
		functions[.getCellularNetworkMode] = GetCellularNetworkModeFunction()
		
		functions[.getWifiConfiguration] = GetWiFiConfiguration()
		functions[.setWifiConfiguration] = SetWiFiConfiguration()
		
		functions[.getSystemTemperature] = GetSystemTemperature()
		functions[.sendSMS] = SendSMS()
		
		functions[.getSMSList] = GetSMSList()
		functions[.deleteSMS] = DeleteSMS()
		
		functions[.markSMS] = MarkSMSRead()
		
		functions[.getAdminAccessRestrictions] = GetAdminRestriction()

		functions[.getCallLogs] = GetCallLogs()
		functions[.clearCallLogs] = ClearCallLogs()

		functions[.getMissedCallCount] = GetMissedCallCount()
		functions[.clearMissedCallCount] = ClearMissedCallCount()

		functions[.getOutboundFirewall] = GetOutboundFirewall()
		functions[.setOutboundFirewall] = SetOutboundFirewall()

		functions[.getInboundFirewall] = GetInboundFirewall()
		functions[.setInboundFirewall] = SetInboundFirewall()

		functions[.getIPAddressConfiguration] = GetIPAddressConfiguration()
		functions[.setIPAddressConfiguration] = SetIPAddressConfiguration()

		functions[.getQualityOfService] = GetQualityOfService()
		functions[.setQualityOfService] = SetQualityOfService()

		functions[.getDMZ] = GetDMZ()
		functions[.setDMZ] = SetDMZ()

		functions[.getPortForwardingConfiguration] = GetPortForwarding()
		functions[.setPortForwardingConfiguration] = SetPortForwarding()

		functions[.getMACAddressFilteringConfiguration] = GetMACAddressFiltering()
		functions[.setMACAddressFilteringConfiguration] = SetMACAddressFiltering()

		functions[.getEmergencyNumber] = GetEmergencyNumber()
		functions[.setEmergencyNumber] = SetEmergencyNumber()

		functions[.getCellularNetworkRoaming] = GetCellularNetworkRoamingFunction()
		functions[.setCellularNetworkRoaming] = SetCellularNetworkRoamingFunction()

		functions[.getCallStatus] = GetCallStatusFunction()
		functions[.getDataUsage] = GetDataUsageFunction()

		functions[.getSIMStatus] = GetSIMStatusFunction()
		functions[.setSIMPIN] = SetSIMPinFunction()
		functions[.unlockSIM] = UnlockSIMFunction()

		functions[.getGNSSSetting] = GetGNSSSettingFunction()
		functions[.setGNSSSetting] = SetGNSSSettingFunction()

		functions[.getHardwareDiagnosticInfo] = GetHardwareDiagnosticInfoFunction()

		functions[.powerDown] = PowerDownFunction()
		functions[.reset] = ResetFunction()

		functions[.getPOSTResults] = GetPOSTResult()
		functions[.getRealTimeResults] = GetRealTimeResult()
		
		functions[.getSystemAlerts] = GetSystemAlertsFunction()

		functions[.getWiFiConnections] = GetWiFiConnectionsFunction()

		functions[.getAudibleAlertOption] = GetAudibleAlertsFunction()
		functions[.setAudibleAlertOption] = SetAudibleAlertsFunction()

		functions[.getUnreadMessageCount] = GetUnreadMessageCountFunction()

		functions[.setAdminAccessRestrictions] = SetAdminRestriction()

		functions[.deleteCallLogs] = DeleteCallLogs()
		functions[.getGNSSLocationInformation] = GetGNSSLocationDiagnosticInfoFunction()

		functions[.getDataService] = GetDataServiceFunction()
		functions[.setDataService] = SetDataServiceFunction()
	}
	
	func handle(request: JSON, forResponder responder: Responder) {
		// Do we have a type
		guard let typeCode = request["header"]["type"].int else {
			return
		}
		// Look up the script
		let requestType = RequestType.for(typeCode)
		log(info: "requestType: \(requestType)")
		guard let function = functions[requestType] else {
			log(info: "No handler for request \(requestType) (\(typeCode))")
			responder.sendUnsupportedAPIResponse(for: typeCode)
			return
		}
		do {
			try function.handle(request: request, forResponder: responder)
		} catch let error {
			log(error: "\(error)")
			responder.failed(request: requestType, with: .failure)
		}
	}
}

