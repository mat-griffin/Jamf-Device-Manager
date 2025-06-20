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
    private var progressSection: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Progress would be displayed here
                Text("Progress tracking implementation would go here")
                    .foregroundColor(.secondary)
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
    
    // MARK: - Helper Methods
    
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
        
        // Implementation would go here
        try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate processing
        
        isProcessing = false
        showAlert(title: "Complete", message: "Mass redeploy operation completed")
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