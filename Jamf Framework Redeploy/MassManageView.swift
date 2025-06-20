//
//  MassManageView.swift
//  Jamf Device Manager
//

import SwiftUI

struct MassManageView: View {
    @ObservedObject var csvHandler: CSVHandler
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedState: ManagementTargetState = .managed
    @State private var shouldLockDevice = false
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var showingLockConfirmation = false
    @State private var alertMessage = ""
    @State private var isDragOver = false
    @State private var isProcessing = false
    @State private var processedCount = 0
    
    enum ManagementTargetState: String, CaseIterable {
        case managed = "Managed"
        case unmanaged = "Unmanaged"
        
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
                        Toggle("Lock devices with random PINs", isOn: $shouldLockDevice)
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
                            if shouldLockDevice {
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
                Text(computer.serialNumber)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
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
        processedCount = 0
        
        // Simulate processing
        for (index, _) in csvHandler.computers.enumerated() {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
            processedCount = index + 1
        }
        
        isProcessing = false
        showAlert(message: "Mass management operation completed successfully")
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