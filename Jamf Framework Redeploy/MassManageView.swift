//
//  MassManageView.swift
//  Jamf Device Manager
//

import SwiftUI

struct MassManageView: View {
    @ObservedObject var csvHandler: CSVHandler
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedState: ManagementTargetState = .unmanaged
    @State private var shouldLockDevice = false
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var showingLockConfirmation = false
    @State private var alertMessage = ""
    @State private var isDragOver = false
    @State private var isProcessing = false
    @State private var processedCount = 0
    
    enum ManagementTargetState: String, CaseIterable {
        case managed = "Manage"
        case unmanaged = "Unmanage"
        
        var iconName: String {
            switch self {
            case .managed:
                return "checkmark.shield"
            case .unmanaged:
                return "xmark.shield"
            }
        }
        
        var isManaged: Bool {
            return self == .managed
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                HStack {
                    Spacer()
                    mainContent(geometry: geometry)
                    Spacer()
                }
                .padding(DesignSystem.Spacing.xl)
            }
        }
        .alert("Operation Complete", isPresented: $showingAlert) {
            Button("OK") { showingAlert = false }
        } message: {
            Text(alertMessage)
        }
    }
    
    @ViewBuilder
    private func mainContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            headerSection
            csvImportSection
            
            if !csvHandler.computers.isEmpty {
                managementControlsSection
                
                if isProcessing {
                    progressSection
                }
                
                computerListSection
            } else {
                dropZoneSection
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: geometry.size.width * 0.8)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.csv],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Lock Confirmation", isPresented: $showingLockConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Continue", role: .destructive) {
                Task {
                    await startMassManagement()
                }
            }
        } message: {
            Text("This will lock all computers during the management state change. Continue?")
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        SectionHeader(
            icon: "list.bullet.rectangle",
            title: "Mass Management State & Lock",
            subtitle: "Change the management state of multiple devices in Jamf Pro using CSV import. Optionally lock devices with random PINs when moving to Unmanaged.",
            iconColor: DesignSystem.Colors.info
        )
    }
    
    @ViewBuilder
    private var csvImportSection: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Label("CSV Import", systemImage: "doc.text")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    ActionButton(
                        title: "Import CSV",
                        icon: "doc.badge.plus",
                        style: .secondary,
                        isDisabled: isProcessing,
                        action: {
                            showingFilePicker = true
                        }
                    )
                    
                    Spacer()
                    
                    if !csvHandler.computers.isEmpty {
                        Text("\(csvHandler.computers.count) computers loaded")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var managementControlsSection: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Label("Management Options", systemImage: "switch.2")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Select the target management state:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(ManagementTargetState.allCases, id: \.self) { state in
                            Button(action: {
                                selectedState = state
                            }) {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    Image(systemName: state.iconName)
                                    Text(state.rawValue)
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.vertical, DesignSystem.Spacing.sm)
                                .frame(maxWidth: .infinity)
                                .background(selectedState == state ? Color.accentColor : Color.clear)
                                .foregroundColor(selectedState == state ? .white : .primary)
                                .cornerRadius(DesignSystem.CornerRadius.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                        .stroke(Color.accentColor, lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    if selectedState == .unmanaged {
                        Toggle("Lock devices with random PIN", isOn: $shouldLockDevice)
                            .toggleStyle(SwitchToggleStyle())
                    }
                }
                
                HStack {
                    ActionButton(
                        title: isProcessing ? "Processing..." : "Start Mass Management",
                        icon: isProcessing ? nil : "play.fill",
                        style: .destructive,
                        isLoading: isProcessing,
                        isDisabled: isProcessing || !authManager.hasValidCredentials,
                        action: {
                            if selectedState == .unmanaged && shouldLockDevice {
                                showingLockConfirmation = true
                            } else {
                                Task {
                                    await startMassManagement()
                                }
                            }
                        }
                    )
                    
                    Spacer()
                    
                    ActionButton(
                        title: "Clear List",
                        icon: "trash",
                        style: .secondary,
                        isDisabled: isProcessing,
                        action: {
                            csvHandler.clearComputers()
                        }
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var progressSection: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack {
                        Text("Progress: \(processedCount) / \(csvHandler.computers.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        let progressPercentage = csvHandler.computers.isEmpty ? 0 : Int((Double(processedCount) / Double(csvHandler.computers.count)) * 100)
                        Text("\(progressPercentage)%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: csvHandler.computers.isEmpty ? 0 : Double(processedCount), total: Double(csvHandler.computers.count))
                        .progressViewStyle(LinearProgressViewStyle())
                        .accentColor(.blue)
                }
            }
        }
    }
    
    @ViewBuilder
    private var computerListSection: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Label("Computer List", systemImage: "list.bullet")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.xs) {
                        ForEach(csvHandler.computers) { computer in
                            computerRow(computer: computer)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }
    
    @ViewBuilder
    private var dropZoneSection: some View {
        CardContainer {
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: isDragOver ? "doc.badge.plus" : "doc.text")
                    .font(.system(size: 48))
                    .foregroundColor(isDragOver ? .accentColor : .secondary)
                
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("Drop Zone")
                        .font(.headline)
                        .foregroundColor(isDragOver ? .accentColor : .primary)
                    
                    Text("No computers loaded")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Import a CSV file or drag one here to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isDragOver ? Color.accentColor : Color.gray.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: isDragOver ? [] : [10, 5])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isDragOver ? Color.accentColor.opacity(0.1) : Color.clear)
                    )
            )
            .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                handleDrop(providers: providers)
            }
        }
    }
    
    @ViewBuilder
    private func computerRow(computer: ComputerRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if let jamfComputerID = computer.jamfComputerID {
                    Button(action: {
                        openJamfComputerRecord(computerID: jamfComputerID)
                    }) {
                        Text(computer.serialNumber)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .underline()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Click to open computer record in Jamf Pro")
                } else {
                    Text(computer.serialNumber)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                if let computerName = computer.computerName {
                    Text(computerName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(statusText(for: computer.status))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: computer.status))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                
                if let error = computer.errorMessage {
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(computer.status == .inProgress ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                .animation(.easeInOut(duration: 0.3), value: computer.status)
        )
    }
    
    // MARK: - Helper Methods
    
    private func statusText(for status: ComputerRecord.DeploymentStatus) -> String {
        switch status {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
    
    private func statusColor(for status: ComputerRecord.DeploymentStatus) -> Color {
        switch status {
        case .pending: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                do {
                    let _ = url.startAccessingSecurityScopedResource()
                    try csvHandler.loadComputers(from: url)
                    url.stopAccessingSecurityScopedResource()
                } catch {
                    showAlert(message: "Import Error: \(error.localizedDescription)")
                }
            }
        case .failure(let error):
            showAlert(message: "File Selection Error: \(error.localizedDescription)")
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        _ = provider.loadObject(ofClass: URL.self) { url, error in
            DispatchQueue.main.async {
                if let url = url {
                    do {
                        try csvHandler.loadComputers(from: url)
                    } catch {
                        showAlert(message: "Drop Error: \(error.localizedDescription)")
                    }
                } else if let error = error {
                    showAlert(message: "Drop Error: \(error.localizedDescription)")
                }
            }
        }
        return true
    }
    
    private func startMassManagement() async {
        isProcessing = true
        csvHandler.isProcessing = true
        processedCount = 0
        
        // Update all devices to in progress status
        for computer in csvHandler.computers {
            csvHandler.updateComputerStatus(computer.id, status: .inProgress, error: nil)
        }
        
        let actionFramework = authManager.getActionFramework()
        let jamfAPI = JamfProAPI()
        var successCount = 0
        var errorCount = 0
        var lockErrors: [String] = []
        var lockPins: [String: String] = [:] // serialNumber -> PIN mapping
        
        // Ensure we have a fresh token before starting bulk operations
        if actionFramework.getCurrentToken() == nil {
            let authSuccess = await authManager.authenticate()
            if !authSuccess {
                showAlert(message: "Failed to authenticate. Please check your credentials.")
                csvHandler.isProcessing = false
                isProcessing = false
                return
            }
        }
        
        // Process each device individually to handle locking
        for (index, computer) in csvHandler.computers.enumerated() {
            let serialNumber = computer.serialNumber
            var operationSuccess = true
            var errorMessage: String? = nil
            var computerID: Int? = nil
            
            // If moving to unmanaged and locking is enabled, lock the device FIRST (while managed)
            if selectedState == .unmanaged && shouldLockDevice {
                // Generate a random 6-digit PIN
                let lockPin = String(format: "%06d", Int.random(in: 100000...999999))
                
                // Get current device info for computer ID
                let currentStateResult = await actionFramework.getDeviceManagementState(
                    jssURL: authManager.jssURL,
                    serialNumber: serialNumber
                )
                
                if currentStateResult.success {
                    computerID = currentStateResult.computerID
                    
                    // Ensure we have a fresh token for the lock command
                    var token = actionFramework.getCurrentToken()
                    if token == nil {
                        // Token expired, refresh it
                        let authSuccess = await authManager.authenticate()
                        if authSuccess {
                            token = actionFramework.getCurrentToken()
                        }
                    }
                    
                    // Send lock command while device is still managed
                    if let validToken = token {
                        let lockResult = await jamfAPI.lockComputer(
                            jssURL: authManager.jssURL,
                            authToken: validToken,
                            computerID: currentStateResult.computerID,
                            pin: lockPin
                        )
                        
                        if lockResult == nil || lockResult != 201 {
                            operationSuccess = false
                            errorMessage = "Failed to lock device (Status: \(lockResult ?? 0))"
                            lockErrors.append("\(serialNumber): Lock failed")
                        } else {
                            // Store successful lock PIN for user reference
                            lockPins[serialNumber] = lockPin
                        }
                    } else {
                        operationSuccess = false
                        errorMessage = "Authentication token unavailable for locking"
                    }
                } else {
                    operationSuccess = false
                    errorMessage = "Failed to get device information for locking"
                }
            }
            
            // Only proceed with management state change if lock succeeded (or lock not requested)
            if operationSuccess {
                let result = await actionFramework.changeDeviceManagementState(
                    jssURL: authManager.jssURL,
                    serialNumber: serialNumber,
                    newState: selectedState.isManaged
                )
                
                if result.success {
                    computerID = result.computerID
                    successCount += 1
                    csvHandler.updateComputerStatus(computer.id, status: .completed, error: nil, jamfComputerID: computerID)
                } else {
                    errorCount += 1
                    csvHandler.updateComputerStatus(computer.id, status: .failed, error: result.error ?? "Management state change failed")
                }
            } else {
                errorCount += 1
                csvHandler.updateComputerStatus(computer.id, status: .failed, error: errorMessage ?? "Operation failed")
            }
            
            // Update progress
            processedCount = index + 1
            
            // Refresh token periodically during long operations (every 10 devices)
            if index > 0 && (index + 1) % 10 == 0 {
                if actionFramework.getCurrentToken() == nil {
                    let authSuccess = await authManager.authenticate()
                    if !authSuccess {
                        // If we can't refresh the token, mark remaining devices as failed
                        for remainingIndex in (index + 1)..<csvHandler.computers.count {
                            let remainingComputer = csvHandler.computers[remainingIndex]
                            csvHandler.updateComputerStatus(remainingComputer.id, status: .failed, error: "Authentication token expired and refresh failed")
                            errorCount += 1
                        }
                        break
                    }
                }
            }
            
            // Small delay to avoid overwhelming the API
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        // Show appropriate alert based on results
        var message = ""
        if errorCount == 0 {
            message = "Mass management operation completed successfully (\(successCount) devices)"
            if selectedState == .unmanaged && shouldLockDevice && !lockPins.isEmpty {
                message += "\n\nAll devices have been locked with random PINs before unmanaging."
            }
        } else if successCount == 0 {
            message = "Mass management operation failed (\(errorCount) errors)"
        } else {
            message = "Mass management operation completed with \(successCount) successes and \(errorCount) errors"
            if selectedState == .unmanaged && shouldLockDevice {
                if !lockPins.isEmpty {
                    message += "\n\n\(lockPins.count) devices were successfully locked before unmanaging."
                }
                if !lockErrors.isEmpty {
                    message += "\n\nDevices that failed to lock: \(lockErrors.joined(separator: ", "))"
                }
            }
        }
        
        showAlert(message: message)
        
        csvHandler.isProcessing = false
        isProcessing = false
    }
    
    private func openJamfComputerRecord(computerID: Int) {
        let jamfURL = authManager.jssURL
        if let url = URL(string: "\(jamfURL)/computers.html?id=\(computerID)&o=r") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }
}

#Preview {
    MassManageView(csvHandler: CSVHandler())
        .environmentObject(AuthenticationManager())
}