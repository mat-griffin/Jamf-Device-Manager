//
//  ContentView.swift
//  Jamf Device Manager
//
//  Created by Richard Mallion on 09/01/2023.
//  Updated by Mat Griffin on 18/06/2025.
//  
//  The inspiration for this app is from the Jamf Framework Redeploy app by redScoder.
//  Github: https://github.com/red5coder/Jamf-Framework-Redeploy
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var jamfURL = ""
    @State private var userName = ""
    @State private var password = ""
    @State private var savePassword = false
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var showingHelp = false
    @State private var showingAbout = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // Shared CSV handlers to persist data across tab changes
    @StateObject private var massRedeployCSVHandler = CSVHandler()
    @StateObject private var massManageCSVHandler = CSVHandler()

    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            HStack(spacing: 16) {
                // App Title
                HStack {
                    Image(systemName: "gear.badge")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading) {
                        Text("Jamf Device Manager")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("Multi-function Jamf Pro Tool")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Open Jamf Button
                Button(action: { 
                    if let url = URL(string: authManager.jssURL.isEmpty ? jamfURL : authManager.jssURL), 
                       !authManager.jssURL.isEmpty || jamfURL.validURL {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                        Text("Open Jamf")
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.clear)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(authManager.jssURL.isEmpty && !jamfURL.validURL)
                .opacity((authManager.jssURL.isEmpty && !jamfURL.validURL) ? 0.5 : 1.0)
                
                // Settings Button with Status Indicator
                Button(action: { 
                    showingSettings = true
                }) {
                    HStack(spacing: 6) {
                        ZStack {
                            Image(systemName: "gear")
                            // Status dot
                            Circle()
                                .fill(authManager.isAuthenticated ? Color.green : Color.red)
                                .frame(width: 6, height: 6)
                                .offset(x: 8, y: -8)
                                .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
                        }
                        Text("Settings")
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.clear)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Dark Mode Toggle
                Button(action: { 
                    isDarkMode.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                        Text(isDarkMode ? "Light/Dark" : "Light/Dark")
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.clear)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Help Button
                Button(action: { 
                    showingHelp = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "questionmark.circle")
                        Text("Help")
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.clear)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .help("Open help documentation")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(NSColor.separatorColor)),
                alignment: .bottom
            )
            .shadow(radius: 1, y: 1)
            
            // Tab Selection
            HStack(spacing: 0) {
                ForEach(Array(tabItems.enumerated()), id: \.offset) { index, item in
                    Button(action: { selectedTab = index }) {
                        HStack(spacing: 8) {
                            Image(systemName: item.icon)
                            Text(item.title)
                        }
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .padding(.vertical, 12)
                        .foregroundColor(selectedTab == index ? .white : .primary)
                        .background(selectedTab == index ? Color.accentColor : Color.gray.opacity(0.15))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity)
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(NSColor.separatorColor)),
                alignment: .bottom
            )
            
            // Content Area
            VStack(alignment: .leading) {
                Group {
                    if selectedTab == 0 {
                        SingleRedeployTabView(
                            jamfURL: $jamfURL,
                            userName: $userName,
                            password: $password,
                            savePassword: $savePassword
                        )
                    } else if selectedTab == 1 {
                        BulkRedeployView(csvHandler: massRedeployCSVHandler)
                    } else if selectedTab == 2 {
                        SingleManagementStateView()
                    } else if selectedTab == 3 {
                        MassManageView(csvHandler: massManageCSVHandler)
                    } else {
                        ComingSoonView(tabName: tabItems[selectedTab].title)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            // Footer Bar
            HStack(spacing: 16) {
                // Server URL
                HStack(spacing: 6) {
                    Image(systemName: "server.rack")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text(authManager.jssURL.isEmpty ? "No server configured" : authManager.jssURL)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Authentication Status
                HStack(spacing: 6) {
                    Image(systemName: authManager.isAuthenticated ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(authManager.isAuthenticated ? .green : .red)
                        .font(.caption)
                    Text(authManager.isAuthenticated ? "Authenticated" : "Not Authenticated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .help(authManager.isAuthenticated ? "Successfully authenticated with Jamf Pro" : "Authentication required - Click Settings to configure API credentials")
                
                // Version Info - Clickable to open About
                Button(action: {
                    showingAbout = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .help("Click to view app information")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(NSColor.separatorColor)),
                alignment: .top
            )
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            loadCredentials()
        }
        .onChange(of: jamfURL) { _ in saveCredentials() }
        .onChange(of: userName) { _ in saveCredentials() }
        .onChange(of: savePassword) { _ in saveCredentials() }
        .sheet(isPresented: $showingSettings) {
            SettingsView(authManager: authManager, isPresented: $showingSettings)
                .frame(minWidth: 500, minHeight: 600)
        }
        .sheet(isPresented: $showingHelp) {
            HelpView(isPresented: $showingHelp)
                .frame(minWidth: 800, minHeight: 600)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView(isPresented: $showingAbout)
        }
    }
    
    private var tabItems: [(title: String, icon: String)] {
        [
            ("Framework Redeploy", "desktopcomputer"),
            ("Mass Redeploy", "square.grid.3x3"),
            ("Manage & Lock", "switch.2"),
            ("Mass Manage & Lock", "square.grid.3x3")
        ]
    }
    
    private func loadCredentials() {
        let defaults = UserDefaults.standard
        userName = defaults.string(forKey: "userName") ?? ""
        jamfURL = defaults.string(forKey: "jamfURL") ?? ""
        savePassword = defaults.bool(forKey: "savePassword")
        
        if savePassword {
            let credentialsArray = Keychain().retrieve(service: "co.uk.mallion.Jamf-Framework-Redeploy")
            if credentialsArray.count == 2 {
                userName = credentialsArray[0]
                password = credentialsArray[1]
            }
        }
    }
    
    private func saveCredentials() {
        let defaults = UserDefaults.standard
        defaults.set(userName, forKey: "userName")
        defaults.set(jamfURL, forKey: "jamfURL")
        defaults.set(savePassword, forKey: "savePassword")
        
        if savePassword && !userName.isEmpty && !password.isEmpty {
            Keychain().save(service: "co.uk.mallion.Jamf-Framework-Redeploy", account: userName, data: password)
        }
    }
}

// MARK: - Single Redeploy Tab View
struct SingleRedeployTabView: View {
    @Binding var jamfURL: String
    @Binding var userName: String
    @Binding var password: String
    @Binding var savePassword: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var serialNumber = ""
    @State private var buttonDisabled = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                HStack {
                    Spacer()
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Header Section
                        SectionHeader(
                            icon: "desktopcomputer",
                            title: "Framework Redeploy",
                            subtitle: "Deploy the Jamf Framework (aka self heal) to individual devices in Jamf Pro. This utilizes the InstallEnterpriseApplication MDM command to redeploy the Jamf framework.",
                            iconColor: DesignSystem.Colors.info
                        )
                        
                        // Device Input Section
                        CardContainer {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                                Label("Device Information", systemImage: "laptopcomputer")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                FormField(
                                    label: "Serial Number",
                                    placeholder: "Enter device serial number (e.g., C02XK1JKLVCG)",
                                    text: $serialNumber,
                                    helpText: "Enter the device's serial number (uppercase letters and numbers only, 8-12 characters)."
                                )
                                
                                // Action Button
                                HStack {
                                    Spacer()
                                    ActionButton(
                                        title: buttonDisabled ? "Redeploying Framework..." : "Redeploy Framework",
                                        icon: buttonDisabled ? nil : "gear.badge",
                                        style: .primary,
                                        isLoading: buttonDisabled,
                                        isDisabled: serialNumber.isEmpty || !authManager.hasValidCredentials,
                                        action: redeployAction
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: buttonDisabled)
                                    Spacer()
                                }
                            }
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: geometry.size.width * 0.8)
                    Spacer()
                }
                .padding(DesignSystem.Spacing.xl)
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func redeployAction() {
        guard !serialNumber.isEmpty else {
            return
        }
        
        buttonDisabled = true
        
        Task {
            // Ensure we're authenticated first
            let authenticated = await authManager.ensureAuthenticated()
            
            guard authenticated else {
                await MainActor.run {
                    buttonDisabled = false
                    alertTitle = "Authentication Required"
                    alertMessage = "Please authenticate with Jamf Pro first by going to Settings (⌘,)."
                    showAlert = true
                }
                return
            }
            
            let result = await authManager.getActionFramework().redeployFramework(
                jssURL: authManager.jssURL,
                serialNumber: serialNumber
            )
            
            await MainActor.run {
                buttonDisabled = false
                
                switch result {
                case .success(let message):
                    alertTitle = "Success"
                    alertMessage = message + "\n\nCheck the device's management history for the InstallEnterpriseApplication command."
                case .failure(let error):
                    alertTitle = "Redeploy Failed"
                    alertMessage = error
                case .partialSuccess(let message, let details):
                    alertTitle = "Partial Success"
                    alertMessage = message + "\n\nDetails:\n" + details.joined(separator: "\n")
                }
                showAlert = true
            }
        }
    }
}

// MARK: - Coming Soon View
struct ComingSoonView: View {
    let tabName: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                EmptyStateView(
                    icon: "hammer.circle",
                    title: "Coming Soon",
                    subtitle: "\(tabName) functionality will be implemented in the next phase of development."
                )
                
                if tabName.contains("Bulk State Change") {
                    CardContainer {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Label("Planned Features", systemImage: "list.bullet.clipboard")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                FeatureRow(text: "Bulk management state changes via CSV import")
                                FeatureRow(text: "Progress tracking for large operations")
                                FeatureRow(text: "Detailed success/failure reporting")
                                FeatureRow(text: "Export results to CSV")
                                FeatureRow(text: "Rollback capabilities for failed operations")
                            }
                        }
                    }
                    .frame(maxWidth: 500)
                }
            }
            .padding(DesignSystem.Spacing.xl)
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(DesignSystem.Colors.success)
                .font(.caption)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}



// MARK: - String Extension for URL Validation
extension String {
    var validURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
}

