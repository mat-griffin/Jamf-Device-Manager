//
//  AuthenticationManager.swift
//  Jamf Device Manager
//
//

import Foundation
import SwiftUI

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var jssURL: String = ""
    @Published var clientID: String = ""
    @Published var clientSecret: String = ""
    @Published var saveCredentials: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var authenticationError: String? = nil
    
    private var currentToken: String?
    private var tokenExpiry: Date?
    private let actionFramework = JamfActionFramework()
    
    init() {
        loadCredentials()
        // Try to authenticate with saved credentials if available
        if hasValidCredentials {
            Task {
                await authenticate()
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    func authenticate() async -> Bool {
        guard !jssURL.isEmpty, !clientID.isEmpty, !clientSecret.isEmpty else {
            await MainActor.run {
                authenticationError = "Please provide all required credentials"
                isAuthenticated = false
            }
            return false
        }
        
        let success = await actionFramework.authenticate(
            jssURL: jssURL,
            clientID: clientID,
            secret: clientSecret
        )
        
        await MainActor.run {
            isAuthenticated = success
            if success {
                authenticationError = nil
                persistCredentials()
            } else {
                authenticationError = "Authentication failed. Please check your credentials."
            }
        }
        
        return success
    }
    
    func clearAuthentication() {
        isAuthenticated = false
        currentToken = nil
        tokenExpiry = nil
        authenticationError = nil
        // Also clear the token in the action framework
        actionFramework.clearAuthentication()
    }
    
    // Ensure we're authenticated with current credentials
    func ensureAuthenticated() async -> Bool {
        // Always check if we have valid credentials first
        guard hasValidCredentials else {
            return false
        }
        
        // Check if the action framework has a valid token
        if actionFramework.hasValidToken() {
            // Sync the isAuthenticated flag on main thread
            self.isAuthenticated = true
            return true
        }
        
        // If no valid token, authenticate
        return await authenticate()
    }
    
    // MARK: - Credential Management
    
    private func loadCredentials() {
        let defaults = UserDefaults.standard
        jssURL = defaults.string(forKey: "jamfURL") ?? ""
        clientID = defaults.string(forKey: "clientID") ?? ""
        saveCredentials = defaults.bool(forKey: "saveCredentials")
        
        if saveCredentials {
            let credentialsArray = Keychain().retrieve(service: "co.uk.mallion.Jamf-Framework-Redeploy")
            if credentialsArray.count == 2 {
                clientID = credentialsArray[0]
                clientSecret = credentialsArray[1]
            }
        }
    }
    
    private func persistCredentials() {
        let defaults = UserDefaults.standard
        defaults.set(jssURL, forKey: "jamfURL")
        defaults.set(clientID, forKey: "clientID")
        defaults.set(saveCredentials, forKey: "saveCredentials")
        
        if saveCredentials && !clientID.isEmpty && !clientSecret.isEmpty {
            Keychain().save(service: "co.uk.mallion.Jamf-Framework-Redeploy", account: clientID, data: clientSecret)
        }
    }
    
    func updateCredentials(jssURL: String, clientID: String, clientSecret: String, saveCredentials: Bool) {
        // Check if credentials have actually changed
        let credentialsChanged = self.jssURL != jssURL || self.clientID != clientID || self.clientSecret != clientSecret
        
        self.jssURL = jssURL
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.saveCredentials = saveCredentials
        
        // Only clear authentication if credentials have actually changed
        if credentialsChanged {
            clearAuthentication()
        }
        
        persistCredentials()
    }
    
    // MARK: - Validation
    
    var hasValidCredentials: Bool {
        return !jssURL.isEmpty && !clientID.isEmpty && !clientSecret.isEmpty
    }
    
    // MARK: - Action Framework Access
    
    func getActionFramework() -> JamfActionFramework {
        return actionFramework
    }
}