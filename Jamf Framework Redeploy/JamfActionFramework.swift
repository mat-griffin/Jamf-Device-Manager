//
//  JamfActionFramework.swift
//  Jamf Device Manager
//

import Foundation
import os.log

// MARK: - Action Framework Core
class JamfActionFramework {
    private let api = JamfProAPI()
    private var currentToken: String?
    private var tokenExpiry: Date?
    
    // MARK: - Authentication Management
    func authenticate(jssURL: String, clientID: String, secret: String) async -> Bool {
        let (token, statusCode) = await api.getToken(jssURL: jssURL, clientID: clientID, secret: secret)
        
        guard let token = token, let statusCode = statusCode, statusCode == 200 else {
            Logger.loggerapi.error("Authentication failed with status code: \(statusCode ?? 0, privacy: .public)")
            return false
        }
        
        self.currentToken = token.access_token
        self.tokenExpiry = Date().addingTimeInterval(TimeInterval(token.expires_in))
        Logger.loggerapi.info("Authentication successful, token expires at: \(self.tokenExpiry!, privacy: .public)")
        Logger.loggerapi.info("Token expires_in value: \(token.expires_in, privacy: .public) seconds")
        return true
    }
    
    private func isTokenValid() -> Bool {
        guard let tokenExpiry = tokenExpiry else { 
            Logger.loggerapi.warning("No token expiry date set")
            return false 
        }
        
        let now = Date()
        let expiryWithBuffer = tokenExpiry.addingTimeInterval(-10) // Reduced buffer to 10 seconds
        let isValid = now < expiryWithBuffer
        
        Logger.loggerapi.info("Token validation - Now: \(now, privacy: .public), Expires: \(tokenExpiry, privacy: .public), Valid: \(isValid, privacy: .public)")
        
        return isValid
    }
    
    private func getValidToken() -> String? {
        guard isTokenValid(), let token = currentToken else {
            Logger.loggerapi.warning("Token is invalid or expired")
            return nil
        }
        return token
    }
    
    func clearAuthentication() {
        currentToken = nil
        tokenExpiry = nil
        Logger.loggerapi.info("Authentication tokens cleared from action framework")
    }
    
    func hasValidToken() -> Bool {
        return isTokenValid() && currentToken != nil
    }
    
    func getCurrentToken() -> String? {
        return getValidToken()
    }
    
    // MARK: - Single Device Management State Operations
    
    /// Get current management state for a single device
    func getDeviceManagementState(jssURL: String, serialNumber: String) async -> ManagementStateResult {
        guard let token = getValidToken() else {
            return ManagementStateResult(
                computerID: 0,
                serialNumber: serialNumber,
                computerName: "Unknown",
                currentState: false,
                success: false,
                statusCode: nil,
                error: "Authentication token is invalid",
                userFullName: nil,
                username: nil,
                userEmail: nil
            )
        }
        
        let (computerDetails, statusCode) = await api.getComputerDetailsBySerial(
            jssURL: jssURL,
            authToken: token,
            serialNumber: serialNumber
        )
        
        guard let details = computerDetails, let statusCode = statusCode, statusCode == 200 else {
            return ManagementStateResult(
                computerID: 0,
                serialNumber: serialNumber,
                computerName: "Unknown",
                currentState: false,
                success: false,
                statusCode: statusCode,
                error: "Failed to retrieve device information (Status: \(statusCode ?? 0))",
                userFullName: nil,
                username: nil,
                userEmail: nil
            )
        }
        
        let isManaged = details.general.remoteManagement?.managed ?? false
        
        return ManagementStateResult(
            computerID: details.general.id,
            serialNumber: serialNumber,
            computerName: details.general.name ?? "Unknown",
            currentState: isManaged,
            success: true,
            statusCode: statusCode,
            error: nil,
            userFullName: details.location?.realname,
            username: details.location?.username,
            userEmail: details.location?.emailAddress
        )
    }
    
    /// Change management state for a single device
    func changeDeviceManagementState(jssURL: String, serialNumber: String, newState: Bool) async -> ManagementStateResult {
        guard let token = getValidToken() else {
            return ManagementStateResult(
                computerID: 0,
                serialNumber: serialNumber,
                computerName: "Unknown",
                currentState: false,
                success: false,
                statusCode: nil,
                error: "Authentication token is invalid",
                userFullName: nil,
                username: nil,
                userEmail: nil
            )
        }
        
        // First, get the device details
        let currentStateResult = await getDeviceManagementState(jssURL: jssURL, serialNumber: serialNumber)
        
        if !currentStateResult.success {
            return currentStateResult
        }
        
        // Check if the state is already what we want
        if currentStateResult.currentState == newState {
            return ManagementStateResult(
                computerID: currentStateResult.computerID,
                serialNumber: serialNumber,
                computerName: currentStateResult.computerName,
                currentState: currentStateResult.currentState,
                success: true,
                statusCode: 200,
                error: "Device is already in the desired state (\(newState ? "Managed" : "Unmanaged"))",
                userFullName: currentStateResult.userFullName,
                username: currentStateResult.username,
                userEmail: currentStateResult.userEmail
            )
        }
        
        // Update the management state
        let updateStatusCode = await api.updateComputerManagementState(
            jssURL: jssURL,
            authToken: token,
            computerID: currentStateResult.computerID,
            isManaged: newState
        )
        
        let success = updateStatusCode == 201 || updateStatusCode == 200
        let statusDescription = newState ? "Managed" : "Unmanaged"
        
        return ManagementStateResult(
            computerID: currentStateResult.computerID,
            serialNumber: serialNumber,
            computerName: currentStateResult.computerName,
            currentState: newState,
            success: success,
            statusCode: updateStatusCode,
            error: success ? nil : "Failed to update management state to \(statusDescription) (Status: \(updateStatusCode ?? 0))",
            userFullName: currentStateResult.userFullName,
            username: currentStateResult.username,
            userEmail: currentStateResult.userEmail
        )
    }
    
    // MARK: - Bulk Operations
    
    /// Process multiple devices for management state changes
    func bulkChangeManagementState(jssURL: String, devices: [DeviceInfo], newState: Bool, progressCallback: ((Int, Int) -> Void)? = nil) async -> BulkManagementStateResult {
        var results: [ManagementStateResult] = []
        var successCount = 0
        var errorCount = 0
        
        Logger.loggerapi.info("Starting bulk management state change for \(devices.count, privacy: .public) devices to \(newState ? "Managed" : "Unmanaged", privacy: .public)")
        
        for (index, device) in devices.enumerated() {
            let result = await changeDeviceManagementState(
                jssURL: jssURL,
                serialNumber: device.serialNumber,
                newState: newState
            )
            
            results.append(result)
            
            if result.success {
                successCount += 1
            } else {
                errorCount += 1
            }
            
            // Call progress callback if provided
            progressCallback?(index + 1, devices.count)
            
            // Small delay to avoid overwhelming the API
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        Logger.loggerapi.info("Bulk operation completed: \(successCount, privacy: .public) successful, \(errorCount, privacy: .public) errors")
        
        return BulkManagementStateResult(
            totalProcessed: devices.count,
            successCount: successCount,
            errorCount: errorCount,
            results: results
        )
    }
    
    // MARK: - Framework Redeploy Operations (Enhanced)
    
    /// Redeploy framework for a single device with enhanced error handling
    func redeployFramework(jssURL: String, serialNumber: String) async -> JamfActionResult {
        guard let token = getValidToken() else {
            return .failure(error: "Authentication token is invalid")
        }
        
        // Get computer ID first
        let (computerID, getStatusCode) = await api.getComputerID(
            jssURL: jssURL,
            authToken: token,
            serialNumber: serialNumber
        )
        
        guard let computerID = computerID, let getStatusCode = getStatusCode, getStatusCode == 200 else {
            return .failure(error: "Failed to find device with serial number \(serialNumber) (Status: \(getStatusCode ?? 0))")
        }
        
        // Redeploy framework
        let redeployStatusCode = await api.redeployJamfFramework(
            jssURL: jssURL,
            authToken: token,
            computerID: computerID
        )
        
        guard let statusCode = redeployStatusCode, statusCode == 200 || statusCode == 201 || statusCode == 202 else {
            return .failure(error: "Framework redeploy failed for device \(serialNumber) (Status: \(redeployStatusCode ?? 0))")
        }
        
        return .success(message: "Framework successfully redeployed to device \(serialNumber)")
    }
    
    /// Bulk framework redeploy with progress tracking
    func bulkRedeployFramework(jssURL: String, devices: [DeviceInfo], progressCallback: ((Int, Int) -> Void)? = nil) async -> JamfActionResult {
        var successResults: [String] = []
        var errorResults: [String] = []
        
        Logger.loggerapi.info("Starting bulk framework redeploy for \(devices.count, privacy: .public) devices")
        
        for (index, device) in devices.enumerated() {
            let result = await redeployFramework(jssURL: jssURL, serialNumber: device.serialNumber)
            
            switch result {
            case .success(let message):
                successResults.append(message)
            case .failure(let error):
                errorResults.append("Device \(device.serialNumber): \(error)")
            case .partialSuccess:
                break // Shouldn't happen for single device operations
            }
            
            progressCallback?(index + 1, devices.count)
            
            // Small delay to avoid overwhelming the API
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        let successCount = successResults.count
        let errorCount = errorResults.count
        
        Logger.loggerapi.info("Bulk redeploy completed: \(successCount, privacy: .public) successful, \(errorCount, privacy: .public) errors")
        
        if errorCount == 0 {
            return .success(message: "All \(successCount) devices successfully processed")
        } else if successCount == 0 {
            return .failure(error: "All \(errorCount) devices failed to process")
        } else {
            return .partialSuccess(
                message: "\(successCount) devices successful, \(errorCount) devices failed",
                details: errorResults
            )
        }
    }
}

// MARK: - Supporting Types
struct DeviceInfo {
    let serialNumber: String
    let deviceName: String?
    
    init(serialNumber: String, deviceName: String? = nil) {
        self.serialNumber = serialNumber
        self.deviceName = deviceName
    }
}

// MARK: - Error Types
enum JamfActionError: Error, LocalizedError {
    case authenticationFailed
    case deviceNotFound(serialNumber: String)
    case apiError(statusCode: Int, message: String)
    case invalidInput(message: String)
    case networkError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Failed to authenticate with Jamf Pro"
        case .deviceNotFound(let serialNumber):
            return "Device with serial number '\(serialNumber)' not found"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
} 