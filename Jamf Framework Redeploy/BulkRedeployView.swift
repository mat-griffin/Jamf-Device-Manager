//
//  BulkRedeployView.swift
//  Jamf Device Manager
//

import SwiftUI

struct BulkRedeployView: View {
    @ObservedObject var csvHandler: CSVHandler
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isProcessing = false
    @State private var isDragOver = false
    
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
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.csv],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { showAlert = false }
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
                controlSection
                
                if csvHandler.isProcessing {
                    progressSection
                }
                
                computerListSection
            } else {
                dropZoneSection
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: geometry.size.width * 0.8)
    }
    
    @ViewBuilder
    private var headerSection: some View {
        SectionHeader(
            icon: "square.grid.3x3",
            title: "Mass Framework Redeploy",
            subtitle: "Mass redeploy the Jamf Framework (aka self heal) to multiple devices in Jamf Pro using CSV import. This utilizes the InstallEnterpriseApplication MDM command to redeploy the framework.",
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
                    .help("Import a CSV file with device serial numbers. Required column: 'SerialNumber'. Optional: 'ComputerName', 'Notes'.")
                    
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
    private var controlSection: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Label("Mass Redeploy Controls", systemImage: "gearshape.2")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    ActionButton(
                        title: isProcessing ? "Processing..." : "Start Mass Redeploy",
                        icon: isProcessing ? nil : "play.fill",
                        style: .destructive,
                        isLoading: isProcessing,
                        isDisabled: isProcessing || !authManager.hasValidCredentials,
                        action: {
                            Task {
                                await startBulkRedeploy()
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
                
                if !authManager.hasValidCredentials {
                    Label("Please configure authentication in Settings before proceeding", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
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
    private var progressSection: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack {
                        Text("Progress: \(csvHandler.processedCount) / \(csvHandler.computers.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        let progressPercentage = csvHandler.computers.isEmpty ? 0 : Int((Double(csvHandler.processedCount) / Double(csvHandler.computers.count)) * 100)
                        Text("\(progressPercentage)%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: csvHandler.computers.isEmpty ? 0 : Double(csvHandler.processedCount), total: Double(csvHandler.computers.count))
                        .progressViewStyle(LinearProgressViewStyle())
                        .accentColor(.blue)
                }
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
                    showAlert(title: "Import Error", message: error.localizedDescription)
                }
            }
        case .failure(let error):
            showAlert(title: "File Selection Error", message: error.localizedDescription)
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
                        showAlert(title: "Drop Error", message: error.localizedDescription)
                    }
                } else if let error = error {
                    showAlert(title: "Drop Error", message: error.localizedDescription)
                }
            }
        }
        return true
    }
    
    private func startBulkRedeploy() async {
        isProcessing = true
        csvHandler.isProcessing = true
        
        // Update all devices to in progress status
        for computer in csvHandler.computers {
            csvHandler.updateComputerStatus(computer.id, status: .inProgress, error: nil)
        }
        
        let actionFramework = authManager.getActionFramework()
        var successCount = 0
        var errorCount = 0
        
        // Ensure we have a fresh token before starting bulk operations
        if actionFramework.getCurrentToken() == nil {
            let authSuccess = await authManager.authenticate()
            if !authSuccess {
                showAlert(title: "Authentication Error", message: "Failed to authenticate. Please check your credentials.")
                csvHandler.isProcessing = false
                isProcessing = false
                return
            }
        }
        
        // Process each device individually to capture computer IDs
        for (index, computer) in csvHandler.computers.enumerated() {
            let serialNumber = computer.serialNumber
            
            let result = await actionFramework.redeployFramework(
                jssURL: authManager.jssURL,
                serialNumber: serialNumber
            )
            
            switch result {
            case .success(_):
                // Get the computer ID for this device to enable links
                let deviceStateResult = await actionFramework.getDeviceManagementState(
                    jssURL: authManager.jssURL,
                    serialNumber: serialNumber
                )
                
                let computerID = deviceStateResult.success ? deviceStateResult.computerID : nil
                csvHandler.updateComputerStatus(computer.id, status: .completed, error: nil, jamfComputerID: computerID)
                successCount += 1
                
            case .failure(let error):
                csvHandler.updateComputerStatus(computer.id, status: .failed, error: error)
                errorCount += 1
            
            case .partialSuccess(_, _):
                // Treat partial success as success for individual devices
                let deviceStateResult = await actionFramework.getDeviceManagementState(
                    jssURL: authManager.jssURL,
                    serialNumber: serialNumber
                )
                
                let computerID = deviceStateResult.success ? deviceStateResult.computerID : nil
                csvHandler.updateComputerStatus(computer.id, status: .completed, error: nil, jamfComputerID: computerID)
                successCount += 1
            }
            
            // Update progress
            csvHandler.processedCount = index + 1
            
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
        
        // Show appropriate completion message
        if errorCount == 0 {
            showAlert(title: "Success", message: "Mass framework redeploy completed successfully (\(successCount) devices)")
        } else if successCount == 0 {
            showAlert(title: "Error", message: "Mass framework redeploy failed (\(errorCount) errors)")
        } else {
            showAlert(title: "Partial Success", message: "Mass framework redeploy completed with \(successCount) successes and \(errorCount) errors")
        }
        
        csvHandler.isProcessing = false
        isProcessing = false
    }
    
    private func openJamfComputerRecord(computerID: Int) {
        let jamfURL = authManager.jssURL
        if let url = URL(string: "\(jamfURL)/computers.html?id=\(computerID)&o=r") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

#Preview {
    BulkRedeployView(csvHandler: CSVHandler())
        .environmentObject(AuthenticationManager())
}