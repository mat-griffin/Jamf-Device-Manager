//
//  SingleManagementStateView.swift
//  Jamf Device Manager
//

import SwiftUI
import os.log

struct SingleManagementStateView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var serialNumber = ""
    @State private var isLoading = false
    @State private var showingResult = false
    @State private var resultTitle = ""
    @State private var resultMessage = ""
    @State private var isSuccess = false
    @State private var currentManagementState: Bool? = nil
    @State private var showingDeviceInfo = false
    @State private var deviceInfo: ManagementStateResult? = nil
    @State private var shouldLockDevice = false
    @State private var lockPin = ""
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                HStack {
                    Spacer()
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Header Section
                        SectionHeader(
                            icon: "switch.2",
                            title: "Management State & Lock",
                            subtitle: "Check and modify the management state of individual devices in Jamf Pro. This controls whether a device is actively managed by Jamf Pro policies and configurations. Optionally lock devices with PINs when moving to Unmanaged.",
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
                                    placeholder: "Enter device serial number",
                                    text: $serialNumber,
                                    helpText: "Enter the device's serial number (uppercase letters and numbers only, 8-12 characters)."
                                )
                                
                                // Action Button
                                HStack {
                                    Spacer()
                                    ActionButton(
                                        title: isLoading ? "Checking..." : "Check Status",
                                        icon: isLoading ? nil : "magnifyingglass",
                                        style: .primary,
                                        isLoading: isLoading,
                                        isDisabled: serialNumber.isEmpty || !authManager.hasValidCredentials,
                                        action: {
                                            Task { @MainActor in
                                                await checkDeviceStatus()
                                            }
                                        }
                                    )
                                    Spacer()
                                }
                            }
                        }
                        
                        // Device Info Display
                        if let deviceInfo = deviceInfo {
                            DeviceInfoCard(
                                deviceName: deviceInfo.computerName,
                                serialNumber: deviceInfo.serialNumber,
                                isManaged: deviceInfo.currentState,
                                computerID: deviceInfo.computerID
                            )
                            
                            // Management State Actions
                            if let currentState = currentManagementState {
                                CardContainer {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                                        Label("Management Actions", systemImage: "switch.2")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("Change the management state of this device:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        // Lock Option for Move to Unmanaged (Disruptive Action)
                                        if currentState {
                                            HStack {
                                                Spacer()
                                                VStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
                                                    HStack(spacing: DesignSystem.Spacing.sm) {
                                                        Toggle("", isOn: $shouldLockDevice)
                                                            .labelsHidden()
                                                        
                                                        Image(systemName: "exclamationmark.triangle.fill")
                                                            .foregroundColor(.orange)
                                                            .font(.title3)
                                                        
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text("Lock Mac when moving to Unmanaged")
                                                                .font(.subheadline)
                                                                .fontWeight(.medium)
                                                            Text("This will lock the Mac with a PIN before removing management")
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                        }
                                                    }
                                                    
                                                    if shouldLockDevice {
                                                        Divider()
                                                            .frame(maxWidth: 300)
                                                        
                                                        FormField(
                                                            label: "Lock PIN (6 digits)",
                                                            placeholder: "Enter 6-digit PIN",
                                                            text: $lockPin,
                                                            helpText: "PIN will be required to unlock the Mac after it's moved to Unmanaged"
                                                        )
                                                        .frame(maxWidth: 300)
                                                        .onChange(of: lockPin) { _, newValue in
                                                            // Filter to only numbers and limit to 6 characters
                                                            let filtered = String(newValue.filter { $0.isNumber }.prefix(6))
                                                            if filtered != newValue {
                                                                Task { @MainActor in
                                                                    lockPin = filtered
                                                                }
                                                            }
                                                        }
                                                        .onAppear {
                                                            Task { @MainActor in
                                                                if lockPin.isEmpty {
                                                                    lockPin = generateRandomPin()
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                .padding(DesignSystem.Spacing.lg)
                                                .background(
                                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                                        .fill(Color.orange.opacity(0.1))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                                                .stroke(shouldLockDevice ? Color.orange : Color.orange.opacity(0.3), lineWidth: shouldLockDevice ? 2 : 1)
                                                        )
                                                )
                                                Spacer()
                                            }
                                        }
                                        
                                        HStack(spacing: DesignSystem.Spacing.lg) {
                                            ActionButton(
                                                title: "Move to Managed",
                                                icon: "checkmark.shield",
                                                style: currentState ? .secondary : .success,
                                                isLoading: isLoading,
                                                isDisabled: currentState || isLoading,
                                                action: {
                                                    Task { @MainActor in
                                                        await changeManagementState(to: true)
                                                    }
                                                }
                                            )
                                            
                                            ActionButton(
                                                title: shouldLockDevice ? "Move to Unmanaged & Lock" : "Move to Unmanaged",
                                                icon: shouldLockDevice ? "lock.shield" : "xmark.shield",
                                                style: !currentState ? .secondary : .destructive,
                                                isLoading: isLoading,
                                                isDisabled: !currentState || isLoading || (shouldLockDevice && !isValidPin(lockPin)),
                                                action: {
                                                    Task { @MainActor in
                                                        await changeManagementState(to: false)
                                                    }
                                                }
                                            )
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
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
        .alert(resultTitle, isPresented: $showingResult) {
            Button("OK") { showingResult = false }
        } message: {
            Text(resultMessage)
        }
    }
    
    @MainActor
    private func checkDeviceStatus() async {
        guard !serialNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError(title: "Missing Information", message: "Please enter a serial number")
            return
        }
        
        isLoading = true
        currentManagementState = nil
        deviceInfo = nil
        
        // Ensure we're authenticated first
        let authenticated = await authManager.ensureAuthenticated()
        
        guard authenticated else {
            isLoading = false
            showError(title: "Authentication Required", message: "Please authenticate with Jamf Pro first by going to Settings (⌘,).")
            return
        }
        
        // Get device management state
        let result = await authManager.getActionFramework().getDeviceManagementState(
            jssURL: authManager.jssURL,
            serialNumber: serialNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        isLoading = false
        
        if result.success {
            currentManagementState = result.currentState
            deviceInfo = result
            showingDeviceInfo = true
        } else {
            showError(
                title: "Device Not Found",
                message: result.error ?? "Unable to retrieve device information"
            )
        }
    }
    
    @MainActor
    private func changeManagementState(to newState: Bool) async {
        guard !serialNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError(title: "Missing Information", message: "Please enter a serial number")
            return
        }
        
        isLoading = true
        
        // Ensure we're authenticated first
        let authenticated = await authManager.ensureAuthenticated()
        
        guard authenticated else {
            isLoading = false
            showError(title: "Authentication Required", message: "Please authenticate with Jamf Pro first by going to Settings (⌘,).")
            return
        }
        
        var lockResult: Int? = nil
        var lockSuccess = true
        
        // If setting to unmanaged and lock is enabled, send lock command FIRST (while device is still managed)
        if !newState && shouldLockDevice && isValidPin(lockPin) {
            // Get current device info for computer ID
            let currentStateResult = await authManager.getActionFramework().getDeviceManagementState(
                jssURL: authManager.jssURL,
                serialNumber: serialNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            if currentStateResult.success {
                let jamfApi = JamfProAPI()
                if let token = authManager.getActionFramework().getCurrentToken() {
                    lockResult = await jamfApi.lockComputer(
                        jssURL: authManager.jssURL,
                        authToken: token,
                        computerID: currentStateResult.computerID,
                        pin: lockPin
                    )
                    lockSuccess = lockResult == 201 || lockResult == 200
                } else {
                    lockSuccess = false
                }
            } else {
                lockSuccess = false
            }
        }
        
        // Only proceed with management state change if lock succeeded (or lock not requested)
        let shouldProceed = !shouldLockDevice || lockSuccess
        var result: ManagementStateResult
        
        if shouldProceed {
            // Change management state
            result = await authManager.getActionFramework().changeDeviceManagementState(
                jssURL: authManager.jssURL,
                serialNumber: serialNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                newState: newState
            )
        } else {
            // Create failure result if lock failed
            result = ManagementStateResult(
                computerID: 0,
                serialNumber: serialNumber,
                computerName: "Unknown",
                currentState: true, // Still managed since we didn't change it
                success: false,
                statusCode: lockResult,
                error: "Lock command failed (Status: \(lockResult ?? 0)). Management state not changed.",
                userFullName: nil,
                username: nil,
                userEmail: nil
            )
        }
        
        isLoading = false
        
        if result.success {
            currentManagementState = result.currentState
            deviceInfo = result
            let stateText = newState ? "Managed" : "Unmanaged"
            
            var message = "Device \(result.serialNumber) is now \(stateText)"
            
            if !newState && shouldLockDevice {
                if lockSuccess {
                    message += "\n\nDevice has been locked with PIN: \(lockPin)"
                } else {
                    message += "\n\nWarning: Device state changed but lock command failed (Status: \(lockResult ?? 0))"
                }
            }
            
            showSuccess(
                title: shouldLockDevice && !newState && lockSuccess ? "Device Set to Unmanaged & Locked" : "Management State Updated",
                message: message
            )
            
            // Reset lock options after successful operation
            if !newState {
                shouldLockDevice = false
                lockPin = ""
            }
        } else {
            showError(
                title: "Update Failed",
                message: result.error ?? "Failed to update management state"
            )
        }
    }
    
    @MainActor
    private func showSuccess(title: String, message: String) {
        resultTitle = title
        resultMessage = message
        isSuccess = true
        showingResult = true
    }
    
    @MainActor
    private func showError(title: String, message: String) {
        resultTitle = title
        resultMessage = message
        isSuccess = false
        showingResult = true
    }
    
    private func generateRandomPin() -> String {
        let pin = Int.random(in: 100000...999999)
        return String(pin)
    }
    
    private func isValidPin(_ pin: String) -> Bool {
        return pin.count == 6 && pin.allSatisfy { $0.isNumber }
    }
} 