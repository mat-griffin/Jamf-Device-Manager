//
//  JamfProApi.swift
//  Jamf Device Manager
//
//  Created by Richard Mallion on 10/01/2023.
//  Updated by Mat Griffin on 18/06/2025.

import Foundation
import os.log

struct JamfProAPI {
    
    func getToken(jssURL: String, clientID: String, secret: String ) async -> (JamfOAuth?,Int?) {
        Logger.loggerapi.info("About to fetch an authentication token")
        guard var jamfAuthEndpoint = URL(string: jssURL) else {
            return (nil, nil)
        }
        
        jamfAuthEndpoint.append(path: "/api/oauth/token")

        let parameters = [
            "client_id": clientID,
            "grant_type": "client_credentials",
            "client_secret": secret
        ]

        var authRequest = URLRequest(url: jamfAuthEndpoint)
        authRequest.httpMethod = "POST"
        authRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        authRequest.timeoutInterval = 30.0
        
        let postData = parameters.map { key, value in
            return "\(key)=\(value)"
        }.joined(separator: "&")
        authRequest.httpBody = postData.data(using: .utf8)

        guard let (data, response) = try? await URLSession.shared.data(for: authRequest)
        else {
            return (nil, nil)
        }
        
        let httpResponse = response as? HTTPURLResponse
        if let httpResponse {
            Logger.loggerapi.info("Response from authenticating: \(httpResponse.statusCode, privacy: .public)")
        }

        do {
            let jssToken = try JSONDecoder().decode(JamfOAuth.self, from: data)
            return (jssToken, httpResponse?.statusCode)
        } catch _ {
            return (nil, httpResponse?.statusCode)
        }
    }
    
    
    //1.0.2 Change
    func getComputerID(jssURL: String, authToken: String, serialNumber: String) async -> (Int?,Int?) {
        Logger.loggerapi.info("About to fetch Computer ID for \(serialNumber, privacy: .public)")
        guard var jamfcomputerEndpoint = URLComponents(string: jssURL) else {
            return (nil, nil)
        }
        
        jamfcomputerEndpoint.path="/JSSResource/computers/serialnumber/\(serialNumber)"

        guard let url = jamfcomputerEndpoint.url else {
            return (nil, nil)
        }

        
        var computerRequest = URLRequest(url: url)
        computerRequest.httpMethod = "GET"
        computerRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        computerRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        computerRequest.timeoutInterval = 15.0
        
        guard let (data, response) = try? await URLSession.shared.data(for: computerRequest)
        else {
            return (nil, nil)
        }
        let httpResponse = response as? HTTPURLResponse
        if let httpResponse {
            Logger.loggerapi.info("Response from fetching computer id: \(httpResponse.statusCode, privacy: .public)")
        }
        do {
            let computer = try JSONDecoder().decode(Computer.self, from: data)
            Logger.loggerapi.info("Computer ID found \(computer.computer.general.id, privacy: .public)")
            return (computer.computer.general.id, httpResponse?.statusCode)
        } catch _ {
            return (nil, httpResponse?.statusCode)
        }
    }
    

    func redeployJamfFramework(jssURL: String, authToken: String, computerID: Int) async -> Int? {
        Logger.loggerapi.info("About to redeploy the framework for computer id: \(computerID, privacy: .public)")
        guard var jamfRedeployEndpoint = URLComponents(string: jssURL) else {
            return nil
        }
        
        jamfRedeployEndpoint.path="/api/v1/jamf-management-framework/redeploy/\(computerID)"
        
        guard let url = jamfRedeployEndpoint.url else {
            return nil
        }
        
        var redeployRequest = URLRequest(url: url)
        redeployRequest.httpMethod = "POST"
        redeployRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        redeployRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        redeployRequest.timeoutInterval = 30.0
        
        guard let (_, response) = try? await URLSession.shared.data(for: redeployRequest)
        else {
            return nil
        }
        
        let httpResponse = response as? HTTPURLResponse
        if let httpResponse {
            Logger.loggerapi.info("Response from redeploying framework: \(httpResponse.statusCode, privacy: .public)")
        }
        return httpResponse?.statusCode
    }
    
    // MARK: - Management State Functions
    
    /// Get detailed computer information including management state
    func getComputerDetails(jssURL: String, authToken: String, computerID: Int) async -> (ComputerDetail?, Int?) {
        Logger.loggerapi.info("About to fetch computer details for computer id: \(computerID, privacy: .public)")
        guard var jamfComputerEndpoint = URLComponents(string: jssURL) else {
            return (nil, nil)
        }
        
        jamfComputerEndpoint.path = "/JSSResource/computers/id/\(computerID)"
        
        guard let url = jamfComputerEndpoint.url else {
            return (nil, nil)
        }
        
        var computerRequest = URLRequest(url: url)
        computerRequest.httpMethod = "GET"
        computerRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        computerRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        computerRequest.timeoutInterval = 15.0
        
        guard let (data, response) = try? await URLSession.shared.data(for: computerRequest)
        else {
            return (nil, nil)
        }
        
        let httpResponse = response as? HTTPURLResponse
        if let httpResponse {
            Logger.loggerapi.info("Response from fetching computer details: \(httpResponse.statusCode, privacy: .public)")
        }
        
        do {
            let computer = try JSONDecoder().decode(Computer.self, from: data)
            return (computer.computer, httpResponse?.statusCode)
        } catch {
            Logger.loggerapi.error("Failed to decode computer details: \(error.localizedDescription, privacy: .public)")
            return (nil, httpResponse?.statusCode)
        }
    }
    
    /// Get computer details by serial number (with management state)
    func getComputerDetailsBySerial(jssURL: String, authToken: String, serialNumber: String) async -> (ComputerDetail?, Int?) {
        Logger.loggerapi.info("About to fetch computer details for serial: \(serialNumber, privacy: .public)")
        guard var jamfComputerEndpoint = URLComponents(string: jssURL) else {
            return (nil, nil)
        }
        
        jamfComputerEndpoint.path = "/JSSResource/computers/serialnumber/\(serialNumber)"
        
        guard let url = jamfComputerEndpoint.url else {
            return (nil, nil)
        }
        
        var computerRequest = URLRequest(url: url)
        computerRequest.httpMethod = "GET"
        computerRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        computerRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        computerRequest.timeoutInterval = 15.0
        
        guard let (data, response) = try? await URLSession.shared.data(for: computerRequest)
        else {
            return (nil, nil)
        }
        
        let httpResponse = response as? HTTPURLResponse
        if let httpResponse {
            Logger.loggerapi.info("Response from fetching computer details by serial: \(httpResponse.statusCode, privacy: .public)")
        }
        
        do {
            let computer = try JSONDecoder().decode(Computer.self, from: data)
            return (computer.computer, httpResponse?.statusCode)
        } catch {
            Logger.loggerapi.error("Failed to decode computer details: \(error.localizedDescription, privacy: .public)")
            return (nil, httpResponse?.statusCode)
        }
    }
    
    /// Update computer management state using Classic API - simplified approach
    func updateComputerManagementState(jssURL: String, authToken: String, computerID: Int, isManaged: Bool) async -> Int? {
        Logger.loggerapi.info("About to update management state for computer id: \(computerID, privacy: .public) to \(isManaged ? "Managed" : "Unmanaged", privacy: .public)")
        
        guard var jamfComputerEndpoint = URLComponents(string: jssURL) else {
            return nil
        }
        
        jamfComputerEndpoint.path = "/JSSResource/computers/id/\(computerID)"
        
        guard let url = jamfComputerEndpoint.url else {
            return nil
        }
        
        // Simplified XML payload - just the minimum required
        let xmlPayload = """
        <?xml version="1.0" encoding="UTF-8"?>
        <computer>
            <general>
                <remote_management>
                    <managed>\(isManaged)</managed>
                </remote_management>
            </general>
        </computer>
        """
        
        var computerRequest = URLRequest(url: url)
        computerRequest.httpMethod = "PUT"
        computerRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        computerRequest.setValue("text/xml", forHTTPHeaderField: "content-type")
        computerRequest.setValue("application/xml", forHTTPHeaderField: "Accept")
        computerRequest.timeoutInterval = 20.0
        computerRequest.httpBody = xmlPayload.data(using: .utf8)
        
        guard let (data, response) = try? await URLSession.shared.data(for: computerRequest)
        else {
            return nil
        }
        
        let httpResponse = response as? HTTPURLResponse
        if let httpResponse {
            Logger.loggerapi.info("Response from updating management state: \(httpResponse.statusCode, privacy: .public)")
            if httpResponse.statusCode >= 400 {
                // Log response body for debugging errors
                if let responseString = String(data: data, encoding: .utf8) {
                    Logger.loggerapi.error("Error response body: \(responseString, privacy: .public)")
                }
            }
        }
        return httpResponse?.statusCode
    }
    
    /// Send lock command to a computer with PIN
    func lockComputer(jssURL: String, authToken: String, computerID: Int, pin: String) async -> Int? {
        Logger.loggerapi.info("About to send lock command to computer id: \(computerID, privacy: .public) with PIN")
        guard var jamfCommandEndpoint = URLComponents(string: jssURL) else {
            return nil
        }
        
        // Use the correct Classic API format for device lock with passcode in URL
        jamfCommandEndpoint.path = "/JSSResource/computercommands/command/DeviceLock/passcode/\(pin)/id/\(computerID)"
        
        guard let url = jamfCommandEndpoint.url else {
            return nil
        }
        
        var commandRequest = URLRequest(url: url)
        commandRequest.httpMethod = "POST"
        commandRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        commandRequest.setValue("application/xml", forHTTPHeaderField: "Accept")
        commandRequest.timeoutInterval = 20.0
        
        guard let (data, response) = try? await URLSession.shared.data(for: commandRequest)
        else {
            return nil
        }
        
        let httpResponse = response as? HTTPURLResponse
        if let httpResponse {
            Logger.loggerapi.info("Response from lock command: \(httpResponse.statusCode, privacy: .public)")
            if httpResponse.statusCode >= 400 {
                // Log response body for debugging errors
                if let responseString = String(data: data, encoding: .utf8) {
                    Logger.loggerapi.error("Lock command error response: \(responseString, privacy: .public)")
                }
            }
        }
        return httpResponse?.statusCode
    }
}

// MARK: - Jamf Pro Auth Model
struct JamfOAuth: Decodable {
    let access_token: String
    let expires_in: Int
    enum CodingKeys: String, CodingKey {
        case access_token
        case expires_in
    }
}

struct Computer: Codable {
    let computer: ComputerDetail
}

// MARK: - Enhanced Computer Model
struct ComputerDetail: Codable {
    let general: General
    let location: Location?

    enum CodingKeys: String, CodingKey {
        case general
        case location
    }
}

struct General: Codable {
    let id: Int
    let name: String?
    let serialNumber: String?
    let udid: String?
    let remoteManagement: RemoteManagement?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case serialNumber = "serial_number"
        case udid
        case remoteManagement = "remote_management"
    }
}

struct RemoteManagement: Codable {
    let managed: Bool
    let managementUsername: String?
    
    enum CodingKeys: String, CodingKey {
        case managed
        case managementUsername = "management_username"
    }
}

struct Location: Codable {
    let username: String?
    let realname: String?
    let emailAddress: String?
    let position: String?
    let phone: String?
    let department: String?
    let building: String?
    let room: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case realname
        case emailAddress = "email_address"
        case position
        case phone
        case department
        case building
        case room
    }
}

// MARK: - Management State Result Types
struct ManagementStateResult {
    let computerID: Int
    let serialNumber: String
    let computerName: String
    let currentState: Bool
    let success: Bool
    let statusCode: Int?
    let error: String?
    let userFullName: String?
    let username: String?
    let userEmail: String?
}

struct BulkManagementStateResult {
    let totalProcessed: Int
    let successCount: Int
    let errorCount: Int
    let results: [ManagementStateResult]
}

// MARK: - Action Framework Types
enum JamfActionType {
    case frameworkRedeploy
    case managementStateChange
}

enum JamfActionResult {
    case success(message: String)
    case failure(error: String)
    case partialSuccess(message: String, details: [String])
}

