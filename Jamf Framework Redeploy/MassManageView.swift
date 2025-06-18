//
//  MassManageView.swift
//  Jamf Device Manager
//

import SwiftUI
import UniformTypeIdentifiers

struct MassManageView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @ObservedObject var csvHandler: CSVHandler
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isProcessing = false
    @State private var isDragOver = false
    @State private var selectedState: ManagementState = .unmanaged
    @State private var shouldLockDevice = false
    @State private var showingLockConfirmation = false
    
    enum ManagementState: Int, CaseIterable {
        case unmanaged = 0
        case managed = 1
        
        var displayName: String {
            switch self {
            case .unmanaged: return "Move to Unmanaged"
            case .managed: return "Move to Managed"
            }
        }
        
        var boolValue: Bool {
            return self == .managed
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                HStack {
                    Spacer()
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Header Section
                        SectionHeader(
                            icon: "list.bullet.rectangle",
                            title: "Mass Management State & Lock",
                            subtitle: "Change the management state of multiple devices in Jamf Pro using CSV import. Optionally lock devices with random PINs when moving to Unmanaged.",
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
                                    
                                    Spacer()
                                    
                                    if !csvHandler.computers.isEmpty {
                                        Text("\(csvHandler.computers.count) computers loaded")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        if !csvHandler.computers.isEmpty {
                            // Management Options Section
                            CardContainer {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                                    Label("Management Options", systemImage: "switch.2")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                        Text("Select the target management state:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        HStack {
                                            // Custom segmented control to ensure proper selection display
                                            HStack(spacing: 0) {
                                                Button(action: {
                                                    selectedState = .unmanaged
                                                }) {
                                                    Text("Move to Unmanaged")
                                                        .font(.subheadline)
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 8)
                                                        .frame(minWidth: 140, maxWidth: .infinity)
                                                        .foregroundColor(selectedState == .unmanaged ? .white : .primary)
                                                        .background(selectedState == .unmanaged ? Color.accentColor : Color.clear)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                
                                                Button(action: {
                                                    selectedState = .managed
                                                }) {
                                                    Text("Move to Managed")
                                                        .font(.subheadline)
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 8)
                                                        .frame(minWidth: 140, maxWidth: .infinity)
                                                        .foregroundColor(selectedState == .managed ? .white : .primary)
                                                        .background(selectedState == .managed ? Color.accentColor : Color.clear)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                            )
                                            .frame(maxWidth: 400)
                                            
                                            Spacer()
                                        }
                                        
                                        // Lock Option for Move to Unmanaged
                                        if selectedState == .unmanaged {
                                            Divider()
                                            
                                            HStack {
                                                Spacer()
                                                VStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
                                                    HStack(spacing: DesignSystem.Spacing.sm) {
                                                        Toggle("", isOn: $shouldLockDevice)
                                                            .labelsHidden()
                                                            .help("When enabled, each device will be locked with a random 6-digit PIN before being moved to unmanaged state")
                                                        
                                                        Image(systemName: "exclamationmark.triangle.fill")
                                                            .foregroundColor(.orange)
                                                            .font(.title3)
                                                            .help("WARNING: Locking devices requires physical access to unlock them")
                                                        
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text("Lock Macs when moving to Unmanaged")
                                                                .font(.subheadline)
                                                                .fontWeight(.medium)
                                                            Text("Each Mac will be locked with a unique random PIN before removing management")
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                        }
                                                    }
                                                    
                                                    if shouldLockDevice {
                                                        Divider()
                                                            .frame(maxWidth: 400)
                                                        
                                                        VStack(spacing: DesignSystem.Spacing.xs) {
                                                            HStack(spacing: DesignSystem.Spacing.xs) {
                                                                Image(systemName: "info.circle")
                                                                    .foregroundColor(.blue)
                                                                Text("Random 6-digit PINs will be generated for each device - these are available in Jamf")
                                                                    .font(.caption)
                                                                    .foregroundColor(.secondary)
                                                            }
                                                        }
                                                    }
                                                }
                                                .padding(DesignSystem.Spacing.lg)
                                                .background(
                                                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                                                        .fill(Color.orange.opacity(0.1))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                                                                .stroke(shouldLockDevice ? Color.orange : Color.orange.opacity(0.3), lineWidth: shouldLockDevice ? 2 : 1)
                                                        )
                                                )
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Control Section
                            CardContainer {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                                    Label("Mass Management Controls", systemImage: "gearshape.2")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    HStack {
                                        ActionButton(
                                            title: isProcessing ? "Processing..." : getStartButtonTitle(),
                                            icon: isProcessing ? nil : (shouldLockDevice && selectedState == .unmanaged ? "lock.shield" : "play.fill"),
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
                                                MassManageComputerRowView(computer: computer, authManager: authManager)
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
        .alert("Lock Confirmation", isPresented: $showingLockConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Continue", role: .destructive) {
                Task {
                    await startMassManagement()
                }
            }
        } message: {
            Text("All \(csvHandler.computers.count) devices will be sent a Lock command. The Lock PIN will be recorded in Jamf.\n\nThis action cannot be undone and will require physical access to unlock each device.")
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func getStartButtonTitle() -> String {
        if selectedState == .unmanaged {
            return shouldLockDevice ? "Start Mass Move to Unmanaged & Lock" : "Start Mass Move to Unmanaged"
        } else {
            return "Start Mass Move to Managed"
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
    
    private func startMassManagement() async {
        // Ensure we're authenticated first
        let authenticated = await authManager.ensureAuthenticated()
        
        guard authenticated else {
            showAlert(title: "Authentication Required", message: "Please authenticate with Jamf Pro first by going to Settings (⌘,).")
            return
        }
        
        isProcessing = true
        csvHandler.isProcessing = true
        csvHandler.resetStatus()
        
        let targetState = selectedState.boolValue
        var successCount = 0
        var failCount = 0
        
        for computer in csvHandler.computers {
            csvHandler.updateComputerStatus(computer.id, status: .inProgress)
            
            // Ensure we have a valid token before each operation
            let authenticated = await authManager.ensureAuthenticated()
            guard authenticated else {
                failCount += 1
                csvHandler.updateComputerStatus(
                    computer.id,
                    status: .failed,
                    error: "Authentication failed - token expired"
                )
                continue
            }
            
            var lockResult: Int? = nil
            var lockSuccess = true
            
            // If setting to unmanaged and lock is enabled, send lock command FIRST
            if !targetState && shouldLockDevice {
                // Generate random PIN for this device
                let randomPin = generateRandomPin()
                
                // Get current device info for computer ID
                let currentStateResult = await authManager.getActionFramework().getDeviceManagementState(
                    jssURL: authManager.jssURL,
                    serialNumber: computer.serialNumber
                )
                
                if currentStateResult.success {
                    // Check if device is already unmanaged before attempting lock
                    if !currentStateResult.currentState {
                        // Device is already unmanaged, can't send lock command
                        lockSuccess = false
                        lockResult = 400 // Set to 400 to indicate the expected failure reason
                    } else {
                        // Device is managed, proceed with lock command
                        let jamfApi = JamfProAPI()
                        if let token = authManager.getActionFramework().getCurrentToken() {
                            lockResult = await jamfApi.lockComputer(
                                jssURL: authManager.jssURL,
                                authToken: token,
                                computerID: currentStateResult.computerID,
                                pin: randomPin
                            )
                            lockSuccess = lockResult == 201 || lockResult == 200
                            
                            // Store the PIN in the computer record (you might want to extend ComputerRecord for this)
                            // For now, we'll include it in the success message
                        } else {
                            lockSuccess = false
                        }
                    }
                } else {
                    lockSuccess = false
                }
            }
            
            // Only proceed with management state change if lock succeeded (or lock not requested)
            let shouldProceed = !shouldLockDevice || lockSuccess
            
            if shouldProceed {
                // Ensure token is still valid before management state change
                let stillAuthenticated = await authManager.ensureAuthenticated()
                guard stillAuthenticated else {
                    failCount += 1
                    csvHandler.updateComputerStatus(
                        computer.id,
                        status: .failed,
                        error: "Authentication failed during operation - token expired"
                    )
                    continue
                }
                
                // Change management state
                let result = await authManager.getActionFramework().changeDeviceManagementState(
                    jssURL: authManager.jssURL,
                    serialNumber: computer.serialNumber,
                    newState: targetState
                )
                
                if result.success {
                    successCount += 1
                    csvHandler.updateComputerStatus(
                        computer.id,
                        status: .completed,
                        jamfComputerID: result.computerID
                    )
                } else {
                    failCount += 1
                    csvHandler.updateComputerStatus(
                        computer.id,
                        status: .failed,
                        error: result.error ?? "Management state change failed"
                    )
                }
            } else {
                failCount += 1
                
                // Provide specific error message based on the failure reason
                let errorMessage: String
                if lockResult == 400 {
                    // Check if device was already unmanaged
                    let currentStateResult = await authManager.getActionFramework().getDeviceManagementState(
                        jssURL: authManager.jssURL,
                        serialNumber: computer.serialNumber
                    )
                    
                    if currentStateResult.success && !currentStateResult.currentState {
                        errorMessage = "Lock failed: Mac is already Unmanaged. Only Managed devices can be locked."
                    } else {
                        errorMessage = "Lock command failed (Status: \(lockResult ?? 0)). Management state not changed."
                    }
                } else {
                    errorMessage = "Lock command failed (Status: \(lockResult ?? 0)). Management state not changed."
                }
                
                csvHandler.updateComputerStatus(
                    computer.id,
                    status: .failed,
                    error: errorMessage
                )
            }
            
            // Small delay to avoid overwhelming the API
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
        
        isProcessing = false
        csvHandler.isProcessing = false
        
        let actionText = shouldLockDevice && selectedState == .unmanaged ? "Management & Lock" : "Management"
        showAlert(
            title: "Mass \(actionText) Complete",
            message: "Successfully processed \(successCount) computers. Failed: \(failCount)"
        )
    }
    
    private func generateRandomPin() -> String {
        let pin = Int.random(in: 100000...999999)
        return String(pin)
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

struct MassManageComputerRowView: View {
    let computer: ComputerRecord
    let authManager: AuthenticationManager
    
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
                    .help("Click to open in Jamf Pro")
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
        guard let baseURL = URL(string: authManager.jssURL) else { return }
        
        // Open to the computer's general page
        let jamfComputerURL = baseURL.appendingPathComponent("computers.html")
            .appending(queryItems: [
                URLQueryItem(name: "id", value: String(computerID)),
                URLQueryItem(name: "o", value: "r")
            ])
        
        NSWorkspace.shared.open(jamfComputerURL)
    }
}

struct MassManageView_Previews: PreviewProvider {
    static var previews: some View {
        MassManageView(csvHandler: CSVHandler())
            .frame(width: 600, height: 500)
            .environmentObject(AuthenticationManager())
    }
}