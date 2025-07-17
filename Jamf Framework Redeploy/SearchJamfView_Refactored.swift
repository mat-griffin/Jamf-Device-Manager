//
//  SearchJamfView.swift
//  Jamf Device Manager
//
//  Created by Mat Griffin on 19/06/2025.
//  Refactored by AI Assistant on 25/06/2025.
//

import SwiftUI

// MARK: - Date Formatting Utilities

func formatJamfDate(_ dateString: String?) -> String? {
    guard let dateString = dateString else { return nil }
    
    let formatter = DateFormatter()
    // Jamf typically returns dates in this format
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    formatter.timeZone = TimeZone(identifier: "UTC")
    
    if let date = formatter.date(from: dateString) {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        outputFormatter.timeZone = TimeZone.current
        return outputFormatter.string(from: date)
    }
    
    // Try alternative format if the first one fails
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    if let date = formatter.date(from: dateString) {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        outputFormatter.timeZone = TimeZone.current
        return outputFormatter.string(from: date)
    }
    
    // Return original string if parsing fails
    return dateString
}

// MARK: - Data Models
struct SearchResult {
    let id: Int
    let name: String
    let serialNumber: String
    let username: String
    let userFullName: String
    let model: String
    let isManaged: Bool
}

struct DetailedDeviceInfo {
    let computerDetail: ComputerDetail
    let lastInventoryUpdate: String
    let enrollmentDate: String
    let operatingSystem: String
    let processor: String
    let memory: String
    let storage: String
    let lastCheckIn: String
}

enum ManagementFilter {
    case all
    case managed
    case unmanaged
}

enum SearchFieldType {
    case model
    case serial
    case user
    case computerName
}

// MARK: - Search Manager
@MainActor
class SearchManager: ObservableObject {
    @Published var searchQuery = ""
    @Published var isSearching = false
    @Published var searchResults: [SearchResult] = []
    @Published var deviceDetails: [Int: DetailedDeviceInfo] = [:]
    @Published var loadingDetailsForDevice: Int?
    @Published var managementFilter: ManagementFilter = .managed
    @Published var showAdvancedSearch = false
    @Published var advancedSearchQuery = ""
    @Published var searchModel = false
    @Published var searchSerial = false
    @Published var searchUser = false
    @Published var searchComputerName = false
    @Published var searchProgress: Double = 0.0
    
    private var searchTask: Task<Void, Never>?
    private let jamfAPI = JamfProAPI()
    
    // MARK: - Search Methods
    
    func performSimpleSearch(authManager: AuthenticationManager) {
        guard !searchQuery.isEmpty else { return }
        guard !isSearching else { return }
        
        // Cancel any existing search
        searchTask?.cancel()
        
        searchTask = Task {
            await executeSimpleSearch(authManager: authManager)
        }
    }
    
    func performAdvancedSearch(authManager: AuthenticationManager) {
        guard !advancedSearchQuery.isEmpty else { return }
        guard hasValidAdvancedSearchFields() else { return }
        guard !isSearching else { return }
        
        // Cancel any existing search
        searchTask?.cancel()
        
        searchTask = Task {
            await executeAdvancedSearch(authManager: authManager)
        }
    }
    
    func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
        isSearching = false
        searchProgress = 0.0
    }
    
    func loadDeviceDetails(_ device: SearchResult, authManager: AuthenticationManager) {
        loadingDetailsForDevice = device.id
        
        Task {
            guard let token = authManager.getActionFramework().getCurrentToken() else {
                loadingDetailsForDevice = nil
                return
            }
            
            let (computerDetail, _) = await jamfAPI.getComputerDetails(
                jssURL: authManager.jssURL,
                authToken: token,
                computerID: device.id
            )
            
            loadingDetailsForDevice = nil
            if let detail = computerDetail {
                let hardware = detail.hardware
                let osInfo = "\(hardware?.osName ?? "macOS") \(hardware?.osVersion ?? "")"
                let processorInfo = hardware?.processorType ?? "Unknown Processor"
                let memoryInfo = hardware?.totalRAM != nil ? "\(hardware!.totalRAM! / 1024) GB" : "Unknown"
                let storageInfo = "N/A" // Storage info would need different API call or parsing
                
                // Use reportDate as fallback for last inventory if lastInventoryUpdate is not available
                let lastInventory = formatJamfDate(detail.general.lastInventoryUpdate ?? detail.general.reportDate) ?? "N/A"
                let lastCheckIn = formatJamfDate(detail.general.lastContactTime ?? detail.general.reportDate) ?? "N/A"
                
                deviceDetails[device.id] = DetailedDeviceInfo(
                    computerDetail: detail,
                    lastInventoryUpdate: lastInventory,
                    enrollmentDate: detail.general.lastEnrolledDate ?? "N/A",
                    operatingSystem: osInfo.trimmingCharacters(in: .whitespaces),
                    processor: processorInfo,
                    memory: memoryInfo,
                    storage: storageInfo,
                    lastCheckIn: lastCheckIn
                )
            } else {
                print("Failed to load device details for device ID: \(device.id)")
            }
        }
    }
    
    // MARK: - Advanced Search Helpers
    
    func hasValidAdvancedSearchFields() -> Bool {
        return searchModel || searchSerial || searchUser || searchComputerName
    }
    
    func isFieldEnabled(_ field: SearchFieldType) -> Bool {
        if isSearching {
            return false
        }
        
        let anySelected = searchModel || searchSerial || searchUser || searchComputerName
        
        if !anySelected {
            return true // All fields enabled when none selected
        }
        
        // Only the selected field is enabled
        switch field {
        case .model:
            return searchModel
        case .serial:
            return searchSerial
        case .user:
            return searchUser
        case .computerName:
            return searchComputerName
        }
    }
    
    func toggleSearchField(_ field: SearchFieldType) {
        switch field {
        case .model:
            searchModel.toggle()
        case .serial:
            searchSerial.toggle()
        case .user:
            searchUser.toggle()
        case .computerName:
            searchComputerName.toggle()
        }
    }
    
    // MARK: - Private Methods
    
    private func executeSimpleSearch(authManager: AuthenticationManager) async {
        isSearching = true
        searchResults = []
        searchProgress = 0.0
        
        defer {
            isSearching = false
            searchProgress = 0.0
        }
        
        guard let token = authManager.getActionFramework().getCurrentToken() else {
            print("No valid token available for search")
            return
        }
        
        // Simple search by computer name or username
        let (computers, _) = await jamfAPI.searchComputersByName(
            jssURL: authManager.jssURL,
            authToken: token,
            searchTerm: searchQuery
        )
        
        searchProgress = 0.5
        
        // Convert to SearchResult format and apply filters
        var results: [SearchResult] = []
        
        for computer in computers {
            // Get detailed info to determine management state and user info
            let (detail, _) = await jamfAPI.getComputerDetails(
                jssURL: authManager.jssURL,
                authToken: token,
                computerID: computer.id
            )
            
            if let detail = detail {
                let isManaged = detail.general.remoteManagement?.managed ?? false
                let username = detail.location?.username ?? ""
                let userFullName = detail.location?.realname ?? ""
                let model = detail.hardware?.model ?? "Unknown"
                
                // Apply management filter
                let shouldInclude = switch managementFilter {
                case .all: true
                case .managed: isManaged
                case .unmanaged: !isManaged
                }
                
                if shouldInclude {
                    results.append(SearchResult(
                        id: computer.id,
                        name: computer.name,
                        serialNumber: computer.serialNumber ?? "N/A",
                        username: username,
                        userFullName: userFullName,
                        model: model,
                        isManaged: isManaged
                    ))
                }
            }
        }
        
        searchProgress = 1.0
        searchResults = results
    }
    
    private func executeAdvancedSearch(authManager: AuthenticationManager) async {
        isSearching = true
        searchResults = []
        searchProgress = 0.0
        
        defer {
            isSearching = false
            searchProgress = 0.0
        }
        
        guard let token = authManager.getActionFramework().getCurrentToken() else {
            print("No valid token available for advanced search")
            return
        }
        
        // Get all computers first
        let (allComputers, allStatus) = await jamfAPI.getAllComputers(
            jssURL: authManager.jssURL,
            authToken: token,
            subset: "basic"
        )
        
        guard allStatus == 200 else { return }
        
        print("Optimized advanced search: Processing \(allComputers.count) computers for '\(advancedSearchQuery)'")
        
        // Process in batches with progress updates
        let batchSize = 20
        let totalBatches = (allComputers.count + batchSize - 1) / batchSize
        let maxResults = 50 // Limit results for performance
        var results: [SearchResult] = []
        
        searchProgress = 0.1 // Start progress
        
        // Process computers in concurrent batches
        for batchIndex in 0..<totalBatches {
            // Check for cancellation
            guard !Task.isCancelled else {
                print("Advanced search cancelled at batch \(batchIndex)")
                return
            }
            
            // Ensure we have a fresh token before each batch
            _ = await authManager.ensureAuthenticated()
            guard let freshToken = authManager.getActionFramework().getCurrentToken() else {
                print("Failed to get fresh token for batch \(batchIndex)")
                return
            }
            
            let startIndex = batchIndex * batchSize
            let endIndex = min(startIndex + batchSize, allComputers.count)
            let batch = Array(allComputers[startIndex..<endIndex])
            
            // Process batch concurrently with limited concurrency
            await withTaskGroup(of: SearchResult?.self) { group in
                let concurrentLimit = 5 // Limit concurrent API calls
                var activeTasks = 0
                
                for computer in batch {
                    guard !Task.isCancelled && results.count < maxResults else { break }
                    
                    if activeTasks < concurrentLimit {
                        activeTasks += 1
                        group.addTask {
                            await self.processComputerForAdvancedSearch(
                                computer: computer,
                                authManager: authManager,
                                token: freshToken
                            )
                        }
                    } else {
                        // Wait for a task to complete before starting new ones
                        if let result = await group.next() {
                            if let searchResult = result {
                                results.append(searchResult)
                            }
                            activeTasks -= 1
                        }
                    }
                }
                
                // Collect remaining results
                for await result in group {
                    if let searchResult = result {
                        results.append(searchResult)
                    }
                    if results.count >= maxResults {
                        break
                    }
                }
            }
            
            // Update progress
            let progress = 0.1 + (0.9 * Double(batchIndex + 1) / Double(totalBatches))
            searchProgress = progress
            
            // Early termination if we have enough results
            if results.count >= maxResults {
                print("Found sufficient results (\(results.count)), stopping advanced search early")
                break
            }
            
            // Show partial results every few batches
            if batchIndex % 5 == 0 && !results.isEmpty {
                searchResults = results
            }
            
            // Small delay between batches to prevent API overload
            if batchIndex < totalBatches - 1 { // Don't delay after last batch
                try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
            }
        }
        
        searchProgress = 1.0
        searchResults = results
        print("Optimized advanced search: Found \(results.count) matches")
    }
    
    private func processComputerForAdvancedSearch(
        computer: ComputerSummary,
        authManager: AuthenticationManager,
        token: String
    ) async -> SearchResult? {
        
        // Get detailed info for advanced filtering
        let (detail, _) = await jamfAPI.getComputerDetails(
            jssURL: authManager.jssURL,
            authToken: token,
            computerID: computer.id
        )
        
        guard let detail = detail else { return nil }
        
        let isManaged = detail.general.remoteManagement?.managed ?? false
        let username = detail.location?.username ?? ""
        let userFullName = detail.location?.realname ?? ""
        let model = detail.hardware?.model ?? "Unknown"
        let computerName = detail.general.name ?? ""
        let serialNumber = detail.general.serialNumber ?? ""
        
        // Apply advanced search filters
        var matchesSearch = false
        let query = advancedSearchQuery.lowercased()
        
        if searchModel && model.lowercased().contains(query) {
            matchesSearch = true
        }
        if searchSerial && serialNumber.lowercased().contains(query) {
            matchesSearch = true
        }
        if searchUser && (username.lowercased().contains(query) || userFullName.lowercased().contains(query)) {
            matchesSearch = true
        }
        if searchComputerName && computerName.lowercased().contains(query) {
            matchesSearch = true
        }
        
        // Apply management filter
        let shouldInclude = switch managementFilter {
        case .all: true
        case .managed: isManaged
        case .unmanaged: !isManaged
        }
        
        guard matchesSearch && shouldInclude else { return nil }
        
        return SearchResult(
            id: computer.id,
            name: computerName,
            serialNumber: serialNumber,
            username: username,
            userFullName: userFullName,
            model: model,
            isManaged: isManaged
        )
    }
}

// MARK: - Main Search View
struct SearchJamfView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var searchManager = SearchManager()
    @State private var expandedDeviceID: Int?
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
                            icon: "magnifyingglass",
                            title: "Search Jamf",
                            subtitle: "Search for devices in your Jamf Pro environment. Enter a serial number, computer name, or username to find device information.",
                            iconColor: DesignSystem.Colors.info
                        )
                        
                        // Search Input Section
                        SearchInputSection(searchManager: searchManager)
                        
                        // Advanced Search Section
                        if searchManager.showAdvancedSearch {
                            AdvancedSearchSection(searchManager: searchManager)
                        }
                        
                        // Search Results
                        if !searchManager.searchResults.isEmpty {
                            SearchResultsView(
                                results: searchManager.searchResults,
                                expandedDeviceID: $expandedDeviceID,
                                deviceDetails: searchManager.deviceDetails,
                                loadingDetailsForDevice: searchManager.loadingDetailsForDevice,
                                onDeviceToggle: toggleDeviceDetails
                            )
                        }
                    }
                    .frame(width: geometry.size.width * 0.8)
                    .animation(.easeInOut(duration: 0.3), value: searchManager.showAdvancedSearch)
                    Spacer()
                }
            }
        }
        .navigationTitle("Search Jamf")
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onDisappear {
            searchManager.cancelSearch()
        }
    }
    
    // MARK: - Private Methods
    
    private func toggleDeviceDetails(_ device: SearchResult) {
        if expandedDeviceID == device.id {
            expandedDeviceID = nil
        } else {
            expandedDeviceID = device.id
            if searchManager.deviceDetails[device.id] == nil {
                searchManager.loadDeviceDetails(device, authManager: authManager)
            }
        }
    }
}

// MARK: - Search Input Section
private struct SearchInputSection: View {
    @ObservedObject var searchManager: SearchManager
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Label("Simple Search", systemImage: "magnifyingglass.circle")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    TextField("Full serial number or username", text: $searchManager.searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            searchManager.performSimpleSearch(authManager: authManager)
                        }
                    
                    Text("Search by full serial number or exact username.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Management State Filter
                ManagementFilterSection(managementFilter: $searchManager.managementFilter)
                
                // Action Buttons
                HStack {
                    if searchManager.isSearching {
                        Button(action: searchManager.cancelSearch) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                Text("Cancel Search")
                            }
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        ActionButton(
                            title: "Search",
                            icon: "magnifyingglass",
                            style: .primary,
                            isLoading: false
                        ) {
                            searchManager.performSimpleSearch(authManager: authManager)
                        }
                        .disabled(searchManager.searchQuery.isEmpty)
                        
                        ActionButton(
                            title: searchManager.showAdvancedSearch ? "Hide Advanced" : "Advanced Search",
                            icon: "slider.horizontal.3",
                            style: .secondary,
                            isLoading: false
                        ) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                searchManager.showAdvancedSearch.toggle()
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Management Filter Section
private struct ManagementFilterSection: View {
    @Binding var managementFilter: ManagementFilter
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Management State Filter")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            HStack {
                // Custom segmented control
                HStack(spacing: 0) {
                    ManagementFilterButton(
                        title: "All Devices",
                        filter: .all,
                        currentFilter: managementFilter,
                        action: { managementFilter = .all }
                    )
                    
                    ManagementFilterButton(
                        title: "Managed Only",
                        filter: .managed,
                        currentFilter: managementFilter,
                        action: { managementFilter = .managed }
                    )
                    
                    ManagementFilterButton(
                        title: "Unmanaged Only",
                        filter: .unmanaged,
                        currentFilter: managementFilter,
                        action: { managementFilter = .unmanaged }
                    )
                }
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                Spacer()
            }
        }
    }
}

// MARK: - Management Filter Button
private struct ManagementFilterButton: View {
    let title: String
    let filter: ManagementFilter
    let currentFilter: ManagementFilter
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minWidth: 100, maxWidth: .infinity)
                .foregroundColor(currentFilter == filter ? .white : .primary)
                .background(currentFilter == filter ? Color.accentColor : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Advanced Search Section
private struct AdvancedSearchSection: View {
    @ObservedObject var searchManager: SearchManager
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Label("Advanced Search", systemImage: "slider.horizontal.3")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    TextField("Search term", text: $searchManager.advancedSearchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("Enter a search term and select which fields to search.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Search Field Options
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Search Fields")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        SearchFieldCheckbox(
                            title: "Model (M4, M1, MacBook Air, etc.)",
                            isSelected: $searchManager.searchModel,
                            isEnabled: searchManager.isFieldEnabled(.model)
                        )
                        
                        SearchFieldCheckbox(
                            title: "Partial Serial Number (e.g. K3)",
                            isSelected: $searchManager.searchSerial,
                            isEnabled: searchManager.isFieldEnabled(.serial)
                        )
                        
                        SearchFieldCheckbox(
                            title: "User (username, email, full name)",
                            isSelected: $searchManager.searchUser,
                            isEnabled: searchManager.isFieldEnabled(.user)
                        )
                        
                        SearchFieldCheckbox(
                            title: "Computer Name",
                            isSelected: $searchManager.searchComputerName,
                            isEnabled: searchManager.isFieldEnabled(.computerName)
                        )
                    }
                }
                
                // Progress Bar
                if searchManager.isSearching && searchManager.searchProgress > 0 {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        HStack {
                            Text("Searching...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(searchManager.searchProgress * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: min(max(searchManager.searchProgress, 0.0), 1.0))
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
                
                // Advanced Search Button
                HStack {
                    if searchManager.isSearching {
                        Button(action: searchManager.cancelSearch) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                Text("Cancel Search")
                            }
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        ActionButton(
                            title: "Advanced Search",
                            icon: "magnifyingglass.circle",
                            style: .secondary,
                            isLoading: false
                        ) {
                            searchManager.performAdvancedSearch(authManager: authManager)
                        }
                        .disabled(searchManager.advancedSearchQuery.isEmpty || !searchManager.hasValidAdvancedSearchFields())
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Search Field Checkbox
private struct SearchFieldCheckbox: View {
    let title: String
    @Binding var isSelected: Bool
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Button(action: { isSelected.toggle() }) {
                HStack(spacing: 8) {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .foregroundColor(isSelected ? .blue : .secondary)
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(isEnabled ? .primary : .secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!isEnabled)
            Spacer()
        }
    }
}

// MARK: - Search Results View
struct SearchResultsView: View {
    let results: [SearchResult]
    @Binding var expandedDeviceID: Int?
    let deviceDetails: [Int: DetailedDeviceInfo]
    let loadingDetailsForDevice: Int?
    let onDeviceToggle: (SearchResult) -> Void
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Label("Search Results (\(results.count))", systemImage: "list.bullet")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                LazyVStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(results, id: \.id) { device in
                        SearchResultRow(
                            device: device,
                            isExpanded: expandedDeviceID == device.id,
                            deviceDetails: deviceDetails[device.id],
                            isLoadingDetails: loadingDetailsForDevice == device.id,
                            onToggle: { onDeviceToggle(device) }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let device: SearchResult
    let isExpanded: Bool
    let deviceDetails: DetailedDeviceInfo?
    let isLoadingDetails: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row content
            Button(action: onToggle) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    // Device Icon
                    Image(systemName: "desktopcomputer")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(width: 40)
                    
                    // Device Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(device.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        HStack(spacing: 12) {
                            Text("SN: \(device.serialNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if !device.username.isEmpty {
                                Text("User: \(device.username)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(device.isManaged ? "Managed" : "Unmanaged")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(device.isManaged ? .green : .orange)
                        }
                    }
                    
                    Spacer()
                    
                    // Expand/Collapse Icon
                    if isLoadingDetails {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
            .buttonStyle(PlainButtonStyle())
            .background(Color.clear)
            
            // Expanded details
            if isExpanded {
                if let deviceDetails = deviceDetails {
                    DeviceDetailsView(device: device, deviceDetails: deviceDetails)
                } else if !isLoadingDetails {
                    HStack {
                        Text("No additional details available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(Color.gray.opacity(0.05))
                }
            }
        }
        .background(Color.clear)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Device Details View
struct DeviceDetailsView: View {
    let device: SearchResult
    let deviceDetails: DetailedDeviceInfo
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.xl) {
            // Left column - General info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("General Information")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                InfoRow(label: "Computer ID", value: String(device.id))
                InfoRow(label: "Serial Number", value: device.serialNumber)
                InfoRow(label: "Management State", value: device.isManaged ? "Managed" : "Unmanaged")
                
                if let location = deviceDetails.computerDetail.location {
                    if let email = location.emailAddress, !email.isEmpty {
                        InfoRow(label: "Email", value: email)
                    }
                    if let department = location.department, !department.isEmpty {
                        InfoRow(label: "Department", value: department)
                    }
                    if let building = location.building, !building.isEmpty {
                        InfoRow(label: "Building", value: building)
                    }
                }
            }
            
            Spacer()
            
            // Right column - Hardware specs
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Hardware Specifications")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                InfoRow(label: "Operating System", value: deviceDetails.operatingSystem)
                InfoRow(label: "Processor", value: deviceDetails.processor)
                InfoRow(label: "Memory", value: deviceDetails.memory)
                InfoRow(label: "Model", value: device.model)
                InfoRow(label: "Last Inventory", value: deviceDetails.lastInventoryUpdate)
                InfoRow(label: "Last Check-in", value: deviceDetails.lastCheckIn)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}