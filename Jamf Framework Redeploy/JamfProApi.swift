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
    
    // MARK: - Search Functions
    
    /// Search for computers by name
    func searchComputersByName(jssURL: String, authToken: String, searchTerm: String) async -> ([ComputerSummary], Int?) {
        Logger.loggerapi.info("About to search computers by name: \(searchTerm, privacy: .public)")
        guard var jamfSearchEndpoint = URLComponents(string: jssURL) else {
            return ([], nil)
        }
        
        jamfSearchEndpoint.path = "/JSSResource/computers/match/\(searchTerm)"
        
        guard let url = jamfSearchEndpoint.url else {
            return ([], nil)
        }
        
        var searchRequest = URLRequest(url: url)
        searchRequest.httpMethod = "GET"
        searchRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        searchRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        searchRequest.timeoutInterval = 15.0
        
        guard let (data, response) = try? await URLSession.shared.data(for: searchRequest)
        else {
            return ([], nil)
        }
        
        let httpResponse = response as? HTTPURLResponse
        if let httpResponse {
            Logger.loggerapi.info("Response from computer search: \(httpResponse.statusCode, privacy: .public)")
        }
        
        do {
            let searchResults = try JSONDecoder().decode(ComputerSearchResults.self, from: data)
            return (searchResults.computers, httpResponse?.statusCode)
        } catch {
            Logger.loggerapi.error("Failed to decode computer search results: \(error.localizedDescription, privacy: .public)")
            return ([], httpResponse?.statusCode)
        }
    }
    
    /// Get all computers (with pagination support)
    func getAllComputers(jssURL: String, authToken: String, subset: String = "basic") async -> ([ComputerSummary], Int?) {
        Logger.loggerapi.info("About to fetch all computers")
        guard var jamfComputersEndpoint = URLComponents(string: jssURL) else {
            return ([], nil)
        }
        
        jamfComputersEndpoint.path = "/JSSResource/computers/subset/\(subset)"
        
        guard let url = jamfComputersEndpoint.url else {
            return ([], nil)
        }
        
        var computersRequest = URLRequest(url: url)
        computersRequest.httpMethod = "GET"
        computersRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        computersRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        computersRequest.timeoutInterval = 30.0
        
        guard let (data, response) = try? await URLSession.shared.data(for: computersRequest)
        else {
            return ([], nil)
        }
        
        let httpResponse = response as? HTTPURLResponse
        if let httpResponse {
            Logger.loggerapi.info("Response from get all computers: \(httpResponse.statusCode, privacy: .public)")
        }
        
        do {
            let allComputers = try JSONDecoder().decode(AllComputersResponse.self, from: data)
            return (allComputers.computers, httpResponse?.statusCode)
        } catch {
            Logger.loggerapi.error("Failed to decode all computers: \(error.localizedDescription, privacy: .public)")
            return ([], httpResponse?.statusCode)
        }
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
    let hardware: Hardware?

    enum CodingKeys: String, CodingKey {
        case general
        case location
        case hardware
    }
}

struct General: Codable {
    let id: Int
    let name: String?
    let serialNumber: String?
    let udid: String?
    let remoteManagement: RemoteManagement?
    let lastInventoryUpdate: String?
    let reportDate: String?
    let lastContactTime: String?
    let lastEnrolledDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case serialNumber = "serial_number"
        case udid
        case remoteManagement = "remote_management"
        case lastInventoryUpdate = "last_inventory_update"
        case reportDate = "report_date"
        case lastContactTime = "last_contact_time"
        case lastEnrolledDate = "last_enrolled_date_utc"
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

struct Hardware: Codable {
    let model: String?
    let modelIdentifier: String?
    let osName: String?
    let osVersion: String?
    let osBuild: String?
    let processorType: String?
    let processorArchitecture: String?
    let processorSpeed: Int?
    let numberOfProcessors: Int?
    let numberOfCores: Int?
    let totalRAM: Int?
    let totalDisk: Int?
    let availableDisk: Int?
    
    enum CodingKeys: String, CodingKey {
        case model
        case modelIdentifier = "model_identifier"
        case osName = "os_name"
        case osVersion = "os_version"
        case osBuild = "os_build"
        case processorType = "processor_type"
        case processorArchitecture = "processor_architecture"
        case processorSpeed = "processor_speed_mhz"
        case numberOfProcessors = "number_processors"
        case numberOfCores = "number_cores"
        case totalRAM = "total_ram"
        case totalDisk = "boot_rom_version"
        case availableDisk = "available_ram_slots"
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

// MARK: - Search Data Models

struct ComputerSearchResults: Codable {
    let computers: [ComputerSummary]
}

struct AllComputersResponse: Codable {
    let computers: [ComputerSummary]
}

struct ComputerSummary: Codable {
    let id: Int
    let name: String
    let serialNumber: String?
    let udid: String?
    let macAddress: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case serialNumber = "serial_number"
        case udid
        case macAddress = "mac_address"
    }
}

