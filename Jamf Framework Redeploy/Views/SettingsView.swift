//
//  SettingsView.swift
//  Jamf Device Manager
//
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var authManager: AuthenticationManager
    @Binding var isPresented: Bool
    @State private var tempJssURL: String = ""
    @State private var tempClientID: String = ""
    @State private var tempClientSecret: String = ""
    @State private var tempSaveCredentials: Bool = false
    @State private var tempDashboardSearchFilter: String = ""
    @State private var isTestingConnection = false
    @State private var showingTestResult = false
    @State private var testResultTitle = ""
    @State private var testResultMessage = ""
    @State private var testSuccess = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar with close button
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.cardBackground)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(DesignSystem.Colors.border),
                alignment: .bottom
            )
            
            // Scrollable content area
            ScrollView(.vertical, showsIndicators: true) {
                HStack {
                    Spacer()
                    VStack(spacing: DesignSystem.Spacing.md) {
                        // Application Settings Header Panel
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Image(systemName: "gear")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                Text("Application Settings")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            
                            Text("Configure your Jamf Pro server connection and authentication settings.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                    
                    // Authentication Settings
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Label("Jamf Pro API Credentials", systemImage: "key.fill")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                FormField(
                                    label: "Server URL",
                                    placeholder: "https://your-server.jamfcloud.com",
                                    text: $tempJssURL,
                                    helpText: "Your Jamf Pro server URL (including https://)."
                                )
                                
                                FormField(
                                    label: "API Client ID",
                                    placeholder: "API Client ID from Jamf Pro Settings",
                                    text: $tempClientID,
                                    helpText: "API Client ID from Jamf Pro → Settings → System → API Roles and Clients."
                                )
                                
                                FormField(
                                    label: "API Client Secret",
                                    placeholder: "API Client Secret from Jamf Pro Settings",
                                    text: $tempClientSecret,
                                    isSecure: true,
                                    helpText: "API Client Secret from Jamf Pro → Settings → System → API Roles and Clients."
                                )
                                
                                Toggle("Save credentials to Keychain", isOn: $tempSaveCredentials)
                                    .toggleStyle(SwitchToggleStyle())
                                    .help("When enabled, credentials are securely stored in macOS Keychain for automatic login")
                            }
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                        
                        // Dashboard Settings
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Label("Dashboard Settings", systemImage: "chart.bar")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                FormField(
                                    label: "Advanced Search Group Filter",
                                    placeholder: "e.g. Report: (or leave blank for all groups)",
                                    text: $tempDashboardSearchFilter,
                                    helpText: "Enter a prefix to filter which Advanced Search groups appear in the Dashboard dropdown. Only searches beginning with this text will be shown. Leave blank to show all searches."
                                )
                            }
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                        
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                    // Connection Status
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                Label("Connection Status", systemImage: "wifi")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                    StatusIndicator(
                                        isConnected: authManager.isAuthenticated,
                                        text: authManager.isAuthenticated ? "Connected to Jamf Pro" : "Not Connected"
                                    )
                                    
                                    if let error = authManager.authenticationError {
                                        Text(error)
                                            .font(.caption)
                                            .foregroundColor(DesignSystem.Colors.error)
                                            .lineLimit(2)
                                    }
                                    
                                    ActionButton(
                                        title: isTestingConnection ? "Testing..." : "Test Connection",
                                        icon: isTestingConnection ? nil : "checkmark.circle",
                                        style: .secondary,
                                        isLoading: isTestingConnection,
                                        isDisabled: tempJssURL.isEmpty || tempClientID.isEmpty || tempClientSecret.isEmpty,
                                        width: 160,
                                        action: testConnection
                                    )
                                }
                            }
                            .padding(DesignSystem.Spacing.lg)
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                            .frame(maxWidth: .infinity)
                            
                            // Actions
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                Label("Actions", systemImage: "gearshape.2")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                VStack(spacing: DesignSystem.Spacing.sm) {
                                    ActionButton(
                                        title: "Clear Credentials",
                                        icon: "trash",
                                        style: .destructive,
                                        isDisabled: !authManager.isAuthenticated,
                                        width: 160,
                                        action: clearAuthentication
                                    )
                                    
                                    ActionButton(
                                        title: "Save & Close",
                                        icon: "checkmark",
                                        style: .success,
                                        isDisabled: tempJssURL.isEmpty || tempClientID.isEmpty || tempClientSecret.isEmpty,
                                        width: 160,
                                        action: saveSettings
                                    )
                                }
                            }
                            .padding(DesignSystem.Spacing.lg)
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                            .frame(maxWidth: .infinity)
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: 500)
                    Spacer()
                }
                .padding(DesignSystem.Spacing.lg)
            }
        }
        .frame(minWidth: 500, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadCurrentSettings()
        }
        .alert(testResultTitle, isPresented: $showingTestResult) {
            Button("OK") { showingTestResult = false }
        } message: {
            Text(testResultMessage)
        }
    }
    
    private func loadCurrentSettings() {
        tempJssURL = authManager.jssURL
        tempClientID = authManager.clientID
        tempClientSecret = authManager.clientSecret
        tempSaveCredentials = authManager.saveCredentials
        tempDashboardSearchFilter = authManager.dashboardSearchFilter
    }
    
    private func testConnection() {
        guard !tempJssURL.isEmpty, !tempClientID.isEmpty, !tempClientSecret.isEmpty else {
            showTestResult(title: "Missing Information", message: "Please provide all required credentials to test the connection.", success: false)
            return
        }
        
        isTestingConnection = true
        
        Task {
            // Update auth manager temporarily for testing
            authManager.updateCredentials(
                jssURL: tempJssURL,
                clientID: tempClientID,
                clientSecret: tempClientSecret,
                saveCredentials: tempSaveCredentials
            )
            authManager.updateDashboardSearchFilter(tempDashboardSearchFilter)
            
            let success = await authManager.authenticate()
            
            await MainActor.run {
                isTestingConnection = false
                if success {
                    showTestResult(
                        title: "Connection Successful",
                        message: "Successfully connected to Jamf Pro server. Your credentials are valid.",
                        success: true
                    )
                } else {
                    showTestResult(
                        title: "Connection Failed",
                        message: authManager.authenticationError ?? "Failed to connect to Jamf Pro server. Please check your credentials and server URL.",
                        success: false
                    )
                }
            }
        }
    }
    
    private func saveSettings() {
        authManager.updateCredentials(
            jssURL: tempJssURL,
            clientID: tempClientID,
            clientSecret: tempClientSecret,
            saveCredentials: tempSaveCredentials
        )
        
        // Update dashboard search filter
        authManager.updateDashboardSearchFilter(tempDashboardSearchFilter)
        
        // Close the settings dialog after saving
        isPresented = false
    }
    
    private func clearAuthentication() {
        authManager.clearAuthentication()
        showTestResult(
            title: "Authentication Cleared",
            message: "Authentication session has been cleared. You will need to reconnect when accessing Jamf Pro features.",
            success: true
        )
    }
    
    private func showTestResult(title: String, message: String, success: Bool) {
        testResultTitle = title
        testResultMessage = message
        testSuccess = success
        showingTestResult = true
    }
}