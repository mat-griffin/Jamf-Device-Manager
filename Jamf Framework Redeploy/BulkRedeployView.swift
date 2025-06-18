//
//  BulkRedeployView.swift
//  Jamf Device Manager
//
//

import SwiftUI
import UniformTypeIdentifiers

struct BulkRedeployView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @ObservedObject var csvHandler: CSVHandler
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isProcessing = false
    @State private var isDragOver = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                HStack {
                    Spacer()
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Header Section
                        SectionHeader(
                            icon: "square.grid.3x3",
                            title: "Mass Framework Redeploy",
                            subtitle: "Mass redeploy the Jamf Framework (aka self heal) to multiple devices in Jamf Pro using CSV import. This utilizes the InstallEnterpriseApplication MDM command to redeploy the framework.",
                            iconColor: DesignSystem.Colors.info
                        )
                        
                        // CSV Import Section
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
            
                        
                        if !csvHandler.computers.isEmpty {
                            // Control Section
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
                                        .help("Send InstallEnterpriseApplication command to all devices in the list. This will redeploy the Jamf management framework.")
                                        
                                        Spacer()
                                        
                                        ActionButton(
                                            title: "Clear List",
                                            icon: "trash",
                                            style: .success,
                                            isDisabled: isProcessing,
                                            action: {
                                                csvHandler.clearComputers()
                                            }
                                        )
                                    }
                                }
                            }
                            
                            if csvHandler.totalCount > 0 {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                    HStack {
                                        Text("Progress: \(csvHandler.processedCount) / \(csvHandler.totalCount)")
                                        Spacer()
                                        Text("\(Int((Double(csvHandler.processedCount) / Double(csvHandler.totalCount)) * 100))%")
                                            .fontWeight(.medium)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    
                                    ProgressView(value: Double(csvHandler.processedCount), total: Double(csvHandler.totalCount))
                                        .progressViewStyle(LinearProgressViewStyle())
                                        .scaleEffect(y: 1.5)
                                        .animation(.easeInOut(duration: 0.3), value: csvHandler.processedCount)
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            // Computer List
                            CardContainer {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                                    Label("Computers (\(csvHandler.computers.count))", systemImage: "list.bullet")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    ScrollView {
                                        LazyVStack(spacing: 8) {
                                            ForEach(csvHandler.computers) { computer in
                                                ComputerRowView(computer: computer, jamfURL: authManager.jssURL)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    .frame(maxHeight: 300)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(8)
                                }
                            }
                        } else {
                            // Drag and Drop Zone
                            CardContainer {
                                VStack(spacing: DesignSystem.Spacing.lg) {
                                    Label("Drop Zone", systemImage: "square.and.arrow.down")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    VStack(spacing: 10) {
                                        Image(systemName: isDragOver ? "doc.badge.plus" : "doc.text")
                                            .font(.system(size: 48))
                                            .foregroundColor(isDragOver ? .accentColor : .secondary)
                                            .scaleEffect(isDragOver ? 1.1 : 1.0)
                                            .animation(.easeInOut(duration: 0.2), value: isDragOver)
                                        
                                        Text(isDragOver ? "Drop CSV file here" : "No computers loaded")
                                            .font(.title2)
                                            .foregroundColor(isDragOver ? .accentColor : .secondary)
                                        
                                        if !isDragOver {
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
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: geometry.size.width * 0.8)
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
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            loadCSVFile(url: url)
            
        case .failure(let error):
            showAlert(title: "File Selection Error", message: error.localizedDescription)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        if provider.hasItemConformingToTypeIdentifier("public.file-url") {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                DispatchQueue.main.async {
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil),
                       url.pathExtension.lowercased() == "csv" {
                        // Try to get a security-scoped bookmark for the dropped file
                        do {
                            let bookmarkData = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
                            var isStale = false
                            let resolvedURL = try URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
                            loadCSVFile(url: resolvedURL)
                        } catch {
                            // If bookmark fails, try direct access
                            loadCSVFile(url: url)
                        }
                    } else {
                        showAlert(title: "Invalid File", message: "Please drop a CSV file.")
                    }
                }
            }
        }
        
        return true
    }
    
    private func loadCSVFile(url: URL) {
        do {
            try csvHandler.loadComputers(from: url)
            // Import successful - no popup needed
        } catch {
            showAlert(title: "Import Error", message: error.localizedDescription)
        }
    }
    
    private func startBulkRedeploy() async {
        // Ensure we're authenticated first
        let authenticated = await authManager.ensureAuthenticated()
        
        guard authenticated else {
            showAlert(title: "Authentication Required", message: "Please authenticate with Jamf Pro first by going to Settings (⌘,).")
            return
        }
        
        isProcessing = true
        csvHandler.isProcessing = true
        csvHandler.resetStatus()
        
        for computer in csvHandler.computers {
            csvHandler.updateComputerStatus(computer.id, status: .inProgress)
            
            // Ensure we have a valid token before each operation
            let authenticated = await authManager.ensureAuthenticated()
            guard authenticated else {
                csvHandler.updateComputerStatus(
                    computer.id,
                    status: .failed,
                    error: "Authentication failed - token expired"
                )
                continue
            }
            
            // First get the computer ID for linking purposes
            let jamfApi = JamfProAPI()
            guard let token = authManager.getActionFramework().getCurrentToken() else {
                csvHandler.updateComputerStatus(
                    computer.id,
                    status: .failed,
                    error: "Authentication token invalid"
                )
                continue
            }
            
            let (computerID, getStatusCode) = await jamfApi.getComputerID(
                jssURL: authManager.jssURL,
                authToken: token,
                serialNumber: computer.serialNumber
            )
            
            guard let computerID = computerID, let getStatusCode = getStatusCode, getStatusCode == 200 else {
                csvHandler.updateComputerStatus(
                    computer.id,
                    status: .failed,
                    error: "Computer not found (Status: \(getStatusCode ?? 0))"
                )
                continue
            }
            
            // Now redeploy the framework
            let redeployStatusCode = await jamfApi.redeployJamfFramework(
                jssURL: authManager.jssURL,
                authToken: token,
                computerID: computerID
            )
            
            if redeployStatusCode == 200 || redeployStatusCode == 201 || redeployStatusCode == 202 {
                csvHandler.updateComputerStatus(computer.id, status: .completed, jamfComputerID: computerID)
            } else {
                csvHandler.updateComputerStatus(
                    computer.id,
                    status: .failed,
                    error: "Redeploy command failed (Status: \(redeployStatusCode ?? 0))",
                    jamfComputerID: computerID
                )
            }
            
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
        
        isProcessing = false
        csvHandler.isProcessing = false
        
        let successCount = csvHandler.computers.filter { $0.status == .completed }.count
        let failCount = csvHandler.computers.filter { $0.status == .failed }.count
        
        showAlert(
            title: "Mass Redeploy Complete",
            message: "Successfully processed \(successCount) computers. Failed: \(failCount)"
        )
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

struct ComputerRowView: View {
    let computer: ComputerRecord
    let jamfURL: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if let computerID = computer.jamfComputerID, 
                   (computer.status == .completed || computer.status == .failed) {
                    Button(action: {
                        openInJamf(computerID: computerID)
                    }) {
                        Text(computer.serialNumber)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .underline()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Click to open this device's management history in Jamf Pro")
                } else {
                    Text(computer.serialNumber)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                }
                
                if let computerName = computer.computerName {
                    Text(computerName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let notes = computer.notes {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                StatusBadge(status: computer.status)
                
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
    
    private func openInJamf(computerID: Int) {
        guard let baseURL = URL(string: jamfURL) else { return }
        
        // Try to open directly to Management History, fall back to management page if needed
        let jamfComputerURL = baseURL.appendingPathComponent("computers.html")
            .appending(queryItems: [
                URLQueryItem(name: "id", value: String(computerID)),
                URLQueryItem(name: "o", value: "r"),
                URLQueryItem(name: "v", value: "management"),
                URLQueryItem(name: "tab", value: "Management_History")
            ])
        
        NSWorkspace.shared.open(jamfComputerURL)
    }
}

struct StatusBadge: View {
    let status: ComputerRecord.DeploymentStatus
    
    var body: some View {
        HStack(spacing: 4) {
            if status == .inProgress {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 10, height: 10)
            } else {
                Image(systemName: statusIcon)
                    .font(.caption)
            }
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(statusColor.opacity(0.2))
        .foregroundColor(statusColor)
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: status)
    }
    
    private var statusIcon: String {
        switch status {
        case .pending:
            return "clock"
        case .inProgress:
            return "arrow.clockwise"
        case .completed:
            return "checkmark.circle"
        case .failed:
            return "xmark.circle"
        }
    }
    
    private var statusText: String {
        switch status {
        case .pending:
            return "Pending"
        case .inProgress:
            return "Processing"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .pending:
            return .gray
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
}

struct BulkRedeployView_Previews: PreviewProvider {
    static var previews: some View {
        BulkRedeployView(csvHandler: CSVHandler())
            .frame(width: 600, height: 500)
            .environmentObject(AuthenticationManager())
    }
}