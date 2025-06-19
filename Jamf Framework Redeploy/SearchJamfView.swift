//
//  SearchJamfView.swift
//  Jamf Device Manager
//
//  Created by Mat Griffin on 19/06/2025.
//

import SwiftUI

struct SearchJamfView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var searchQuery = ""
    @State private var isSearching = false
    @State private var searchResults: [SearchResult] = []
    @State private var expandedDeviceID: Int?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var deviceDetails: [Int: DetailedDeviceInfo] = [:]
    @State private var loadingDetailsForDevice: Int?
    @State private var managementFilter: ManagementFilter = .managed
    @State private var showAdvancedSearch = false
    @State private var advancedSearchQuery = ""
    @State private var searchModel = false
    @State private var searchSerial = false
    @State private var searchUser = false
    @State private var searchComputerName = false
    @State private var searchProgress: Double = 0.0
    @State private var searchTask: Task<Void, Never>?
    
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
                        CardContainer {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                                Label("Simple Search", systemImage: "magnifyingglass.circle")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                    //Text("Search Query")
                                    //    .font(.subheadline)
                                    //    .fontWeight(.medium)
                                    //    .foregroundColor(.primary)
                                    
                                    TextField("Full serial number or username", text: $searchQuery)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .onSubmit {
                                            performSearch()
                                        }
                                    
                                    Text("Search by full serial number or exact username.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Management State Filter
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                    Text("Management State Filter")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    HStack {
                                        // Custom segmented control to match Mass Manage style
                                        HStack(spacing: 0) {
                                            Button(action: {
                                                managementFilter = .all
                                            }) {
                                                Text("All Devices")
                                                    .font(.subheadline)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .frame(minWidth: 100, maxWidth: .infinity)
                                                    .foregroundColor(managementFilter == .all ? .white : .primary)
                                                    .background(managementFilter == .all ? Color.accentColor : Color.clear)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            Button(action: {
                                                managementFilter = .managed
                                            }) {
                                                Text("Managed Only")
                                                    .font(.subheadline)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .frame(minWidth: 100, maxWidth: .infinity)
                                                    .foregroundColor(managementFilter == .managed ? .white : .primary)
                                                    .background(managementFilter == .managed ? Color.accentColor : Color.clear)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            Button(action: {
                                                managementFilter = .unmanaged
                                            }) {
                                                Text("Unmanaged Only")
                                                    .font(.subheadline)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .frame(minWidth: 100, maxWidth: .infinity)
                                                    .foregroundColor(managementFilter == .unmanaged ? .white : .primary)
                                                    .background(managementFilter == .unmanaged ? Color.accentColor : Color.clear)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                        )
                                        .frame(maxWidth: 450)
                                        
                                        Spacer()
                                    }
                                }
                                
                                // Search Button
                                HStack {
                                    Spacer()
                                    ActionButton(
                                        title: isSearching ? "Searching..." : "Search Jamf",
                                        icon: isSearching ? nil : "magnifyingglass",
                                        style: .primary,
                                        isLoading: isSearching,
                                        isDisabled: searchQuery.count < 2 || !authManager.hasValidCredentials,
                                        action: performSearch
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: isSearching)
                                    Spacer()
                                }
                            }
                        }
                        
                        // Advanced Search Section
                        CardContainer {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                                HStack {
                                    Label("Advanced Search", systemImage: "slider.horizontal.3")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        showAdvancedSearch.toggle()
                                    }) {
                                        HStack(spacing: 4) {
                                            Text(showAdvancedSearch ? "Hide" : "Show")
                                                .font(.subheadline)
                                            Image(systemName: showAdvancedSearch ? "chevron.up" : "chevron.down")
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                if showAdvancedSearch {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                        Text("Search specific fields by selecting the field types below. Advanced searches can take several minutes to complete.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        // Search Query Field
                                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                           // Text("Search Term")
                                            //    .font(.subheadline)
                                            //    .fontWeight(.medium)
                                            //    .foregroundColor(.primary)
                                            
                                            TextField("M4, MacBook Air, etc.", text: $advancedSearchQuery)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .onSubmit {
                                                    performAdvancedSearch()
                                                }
                                        }
                                        
                                        // Field Selection Checkboxes
                                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                            Text("Search In:")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                                HStack {
                                                    Button(action: { toggleSearchField(.model) }) {
                                                        HStack(spacing: 8) {
                                                            Image(systemName: searchModel ? "checkmark.square.fill" : "square")
                                                                .foregroundColor(searchModel ? .blue : .secondary)
                                                            Text("Model (M4, M1, MacBook Air, etc.)")
                                                                .font(.subheadline)
                                                                .foregroundColor(isFieldEnabled(.model) ? .primary : .secondary)
                                                        }
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                    .disabled(!isFieldEnabled(.model))
                                                    Spacer()
                                                }
                                                
                                                HStack {
                                                    Button(action: { toggleSearchField(.serial) }) {
                                                        HStack(spacing: 8) {
                                                            Image(systemName: searchSerial ? "checkmark.square.fill" : "square")
                                                                .foregroundColor(searchSerial ? .blue : .secondary)
                                                            Text("Partial Serial Number (e.g. K3)")
                                                                .font(.subheadline)
                                                                .foregroundColor(isFieldEnabled(.serial) ? .primary : .secondary)
                                                        }
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                    .disabled(!isFieldEnabled(.serial))
                                                    Spacer()
                                                }
                                                
                                                HStack {
                                                    Button(action: { toggleSearchField(.user) }) {
                                                        HStack(spacing: 8) {
                                                            Image(systemName: searchUser ? "checkmark.square.fill" : "square")
                                                                .foregroundColor(searchUser ? .blue : .secondary)
                                                            Text("User (username, email, full name)")
                                                                .font(.subheadline)
                                                                .foregroundColor(isFieldEnabled(.user) ? .primary : .secondary)
                                                        }
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                    .disabled(!isFieldEnabled(.user))
                                                    Spacer()
                                                }
                                                
                                                HStack {
                                                    Button(action: { toggleSearchField(.computerName) }) {
                                                        HStack(spacing: 8) {
                                                            Image(systemName: searchComputerName ? "checkmark.square.fill" : "square")
                                                                .foregroundColor(searchComputerName ? .blue : .secondary)
                                                            Text("Computer Name")
                                                                .font(.subheadline)
                                                                .foregroundColor(isFieldEnabled(.computerName) ? .primary : .secondary)
                                                        }
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                    .disabled(!isFieldEnabled(.computerName))
                                                    Spacer()
                                                }
                                            }
                                        }
                                        
                                        // Advanced Search Progress
                                        if isSearching && searchProgress > 0 {
                                            VStack(spacing: DesignSystem.Spacing.xs) {
                                                HStack {
                                                    Text("Searching...")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                    Spacer()
                                                    Text("\(Int(searchProgress * 100))%")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                ProgressView(value: min(max(searchProgress, 0.0), 1.0))
                                                    .progressViewStyle(LinearProgressViewStyle())
                                            }
                                        }
                                        
                                        // Advanced Search Button
                                        HStack {
                                            if isSearching {
                                                Spacer()
                                                Button(action: cancelSearch) {
                                                    HStack(spacing: 8) {
                                                        Image(systemName: "xmark.circle.fill")
                                                        Text("Cancel Search")
                                                    }
                                                    .foregroundColor(.red)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                Spacer()
                                            } else {
                                                Spacer()
                                                ActionButton(
                                                    title: "Advanced Search",
                                                    icon: "magnifyingglass.circle",
                                                    style: .secondary,
                                                    isLoading: false,
                                                    isDisabled: advancedSearchQuery.count < 2 || 
                                                               (!searchModel && !searchSerial && !searchUser && !searchComputerName) ||
                                                               !authManager.hasValidCredentials,
                                                    action: performAdvancedSearch
                                                )
                                                Spacer()
                                            }
                                        }
                                    }
                                    .animation(.easeInOut(duration: 0.3), value: showAdvancedSearch)
                                }
                            }
                        }
                        
                        // Search Results Section
                        if !searchResults.isEmpty {
                            SearchResultsView(
                                results: searchResults,
                                expandedDeviceID: $expandedDeviceID,
                                deviceDetails: deviceDetails,
                                loadingDetailsForDevice: loadingDetailsForDevice,
                                onDeviceToggle: { device in
                                    toggleDeviceDetails(device)
                                }
                            )
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: geometry.size.width * 0.9)
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
    
    private func performSearch() {
        guard !searchQuery.isEmpty && searchQuery.count >= 2 else { return }
        
        isSearching = true
        searchResults = []
        
        Task {
            let authenticated = await authManager.ensureAuthenticated()
            
            guard authenticated else {
                await MainActor.run {
                    isSearching = false
                    alertTitle = "Authentication Required"
                    alertMessage = "Please authenticate with Jamf Pro first by going to Settings (⌘,)."
                    showAlert = true
                }
                return
            }
            
            let results = await searchDevices(query: searchQuery)
            
            await MainActor.run {
                isSearching = false
                searchResults = results
                
                if results.isEmpty {
                    alertTitle = "No Results Found"
                    alertMessage = "No devices found matching '\(searchQuery)'. Try a different search term."
                    showAlert = true
                }
            }
        }
    }
    
    private func searchDevices(query: String) async -> [SearchResult] {
        var results: [SearchResult] = []
        let api = JamfProAPI()
        
        // Ensure we have fresh authentication
        let authenticated = await authManager.ensureAuthenticated()
        guard authenticated, let token = authManager.getActionFramework().getCurrentToken() else {
            return []
        }
        
        let searchTerm = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Basic search: Try exact serial number match first
        let (computerDetail, statusCode) = await api.getComputerDetailsBySerial(
            jssURL: authManager.jssURL,
            authToken: token,
            serialNumber: searchTerm.uppercased()
        )
        
        if let detail = computerDetail, statusCode == 200, passesManagementFilter(detail: detail) {
            let result = createSearchResult(from: detail)
            results.append(result)
            return results
        }
        
        // If no serial match, try username-based search
        let (searchResults, searchStatus) = await api.searchComputersByName(
            jssURL: authManager.jssURL,
            authToken: token,
            searchTerm: searchTerm
        )
        
        if searchStatus == 200 {
            let maxResults = min(searchResults.count, 10)
            
            for i in 0..<maxResults {
                let computer = searchResults[i]
                
                guard let currentToken = authManager.getActionFramework().getCurrentToken() else { continue }
                
                let (detail, detailStatus) = await api.getComputerDetails(
                    jssURL: authManager.jssURL,
                    authToken: currentToken,
                    computerID: computer.id
                )
                
                if let detail = detail, detailStatus == 200, passesManagementFilter(detail: detail) {
                    // Simple matching for basic search - just username and computer name
                    let matchesUsername = detail.location?.username?.lowercased().contains(searchTerm.lowercased()) ?? false
                    let matchesComputerName = detail.general.name?.lowercased().contains(searchTerm.lowercased()) ?? false
                    
                    if matchesUsername || matchesComputerName {
                        let result = createSearchResult(from: detail)
                        results.append(result)
                    }
                }
            }
        }
        
        return results
    }
    
    private func performAdvancedSearch() {
        guard !advancedSearchQuery.isEmpty && advancedSearchQuery.count >= 2 else { return }
        guard searchModel || searchSerial || searchUser || searchComputerName else { return }
        
        // Cancel any existing search
        searchTask?.cancel()
        
        isSearching = true
        searchResults = []
        searchProgress = 0.0
        
        searchTask = Task {
            let authenticated = await authManager.ensureAuthenticated()
            
            guard authenticated else {
                await MainActor.run {
                    isSearching = false
                    searchProgress = 0.0
                    alertTitle = "Authentication Required"
                    alertMessage = "Please authenticate with Jamf Pro first by going to Settings (⌘,)."
                    showAlert = true
                }
                return
            }
            
            let results = await searchAllDevicesOptimized(query: advancedSearchQuery)
            
            await MainActor.run {
                isSearching = false
                searchProgress = 0.0
                if !Task.isCancelled {
                    searchResults = results
                    
                    if results.isEmpty {
                        alertTitle = "No Results Found"
                        alertMessage = "No devices found matching '\(advancedSearchQuery)' in the selected fields. Try different search terms or field selections."
                        showAlert = true
                    }
                }
            }
        }
    }
    
    private func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
        isSearching = false
        searchProgress = 0.0
    }
    
    private func searchAllDevicesOptimized(query: String) async -> [SearchResult] {
        var results: [SearchResult] = []
        let api = JamfProAPI()
        
        guard let token = authManager.getActionFramework().getCurrentToken() else {
            return []
        }
        
        let searchTerm = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Get ALL computers for comprehensive search
        let (allComputers, allStatus) = await api.getAllComputers(
            jssURL: authManager.jssURL,
            authToken: token,
            subset: "basic"
        )
        
        guard allStatus == 200 else { return [] }
        
        print("Optimized search: Processing \(allComputers.count) computers for '\(searchTerm)'")
        
        // Process in batches with progress updates
        let batchSize = 20
        let totalBatches = (allComputers.count + batchSize - 1) / batchSize
        let maxResults = 50 // Limit results for performance
        
        await MainActor.run {
            self.searchProgress = 0.1 // Start progress
        }
        
        // Process computers in concurrent batches
        for batchIndex in 0..<totalBatches {
            // Check for cancellation
            guard !Task.isCancelled else {
                print("Search cancelled at batch \(batchIndex)")
                return results
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
                            await self.processComputer(computer: computer, searchTerm: searchTerm, api: api)
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
            await MainActor.run {
                self.searchProgress = progress
            }
            
            // Early termination if we have enough results
            if results.count >= maxResults {
                print("Found sufficient results (\(results.count)), stopping search early")
                break
            }
            
            // Show partial results every few batches
            if batchIndex % 5 == 0 && !results.isEmpty {
                await MainActor.run {
                    self.searchResults = results
                }
            }
        }
        
        print("Optimized search: Found \(results.count) matches")
        return results
    }
    
    private func processComputer(computer: ComputerSummary, searchTerm: String, api: JamfProAPI) async -> SearchResult? {
        // Re-authenticate if needed
        var currentToken = authManager.getActionFramework().getCurrentToken()
        if currentToken == nil {
            _ = await authManager.ensureAuthenticated()
            currentToken = authManager.getActionFramework().getCurrentToken()
        }
        
        guard let validToken = currentToken else { return nil }
        
        let (detail, detailStatus) = await api.getComputerDetails(
            jssURL: authManager.jssURL,
            authToken: validToken,
            computerID: computer.id
        )
        
        if let detail = detail, detailStatus == 200, passesManagementFilter(detail: detail) {
            if advancedMatchesSearchCriteria(detail: detail, query: searchTerm) {
                let searchResult = createSearchResult(from: detail)
                
                // Store the device details for the expanded view
                await MainActor.run {
                    let hardware = detail.hardware
                    let osInfo = "\(hardware?.osName ?? "macOS") \(hardware?.osVersion ?? "")"
                    let processorInfo = hardware?.processorType ?? "Unknown Processor"
                    let memoryInfo = hardware?.totalRAM != nil ? "\(hardware!.totalRAM! / 1024) GB" : "Unknown"
                    let storageInfo = "N/A"
                    
                    let lastInventory = formatJamfDate(detail.general.lastInventoryUpdate ?? detail.general.reportDate) ?? "N/A"
                    let lastCheckIn = formatJamfDate(detail.general.lastContactTime ?? detail.general.reportDate) ?? "N/A"
                    
                    deviceDetails[searchResult.id] = DetailedDeviceInfo(
                        computerDetail: detail,
                        lastInventoryUpdate: lastInventory,
                        enrollmentDate: detail.general.lastEnrolledDate ?? "N/A",
                        operatingSystem: osInfo.trimmingCharacters(in: .whitespaces),
                        processor: processorInfo,
                        memory: memoryInfo,
                        storage: storageInfo,
                        lastCheckIn: lastCheckIn
                    )
                }
                
                return searchResult
            }
        }
        
        return nil
    }
    
    private func advancedMatchesSearchCriteria(detail: ComputerDetail, query: String) -> Bool {
        let queryLower = query.lowercased()
        
        // Check each selected field
        var matches = false
        
        if searchModel {
            let model = detail.hardware?.model?.lowercased() ?? ""
            if model.contains(queryLower) {
                matches = true
            }
        }
        
        if searchSerial {
            let serialNumber = detail.general.serialNumber?.lowercased() ?? ""
            if serialNumber.contains(queryLower) {
                matches = true
            }
        }
        
        if searchUser {
            let username = detail.location?.username?.lowercased() ?? ""
            let userFullName = detail.location?.realname?.lowercased() ?? ""
            let userEmail = detail.location?.emailAddress?.lowercased() ?? ""
            
            if username.contains(queryLower) || 
               userFullName.contains(queryLower) || 
               userEmail.contains(queryLower) ||
               userFullName.components(separatedBy: " ").contains(where: { $0.hasPrefix(queryLower) }) ||
               (userEmail.components(separatedBy: "@").first?.contains(queryLower) ?? false) {
                matches = true
            }
        }
        
        if searchComputerName {
            let computerName = detail.general.name?.lowercased() ?? ""
            if computerName.contains(queryLower) {
                matches = true
            }
        }
        
        return matches
    }
    
    // MARK: - Advanced Search Field Management
    
    private func toggleSearchField(_ field: SearchFieldType) {
        // Check if the field is already selected
        let isCurrentlySelected = switch field {
        case .model: searchModel
        case .serial: searchSerial
        case .user: searchUser
        case .computerName: searchComputerName
        }
        
        // Clear all fields first
        searchModel = false
        searchSerial = false
        searchUser = false
        searchComputerName = false
        
        // If it wasn't selected before, select it now
        // If it was selected, leave it unselected (all fields are now false)
        if !isCurrentlySelected {
            switch field {
            case .model:
                searchModel = true
            case .serial:
                searchSerial = true
            case .user:
                searchUser = true
            case .computerName:
                searchComputerName = true
            }
        }
    }
    
    private func isFieldEnabled(_ field: SearchFieldType) -> Bool {
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
    
    // MARK: - Simple Search Helper Functions
    
    private func passesManagementFilter(detail: ComputerDetail) -> Bool {
        let isManaged = detail.general.remoteManagement?.managed ?? false
        return managementFilter == .all || 
               (managementFilter == .managed && isManaged) ||
               (managementFilter == .unmanaged && !isManaged)
    }
    
    private func createSearchResult(from detail: ComputerDetail) -> SearchResult {
        return SearchResult(
            id: detail.general.id,
            name: detail.general.name ?? "Unknown",
            serialNumber: detail.general.serialNumber ?? "",
            username: detail.location?.username ?? "",
            userFullName: detail.location?.realname ?? "",
            model: detail.hardware?.model ?? "Mac",
            isManaged: detail.general.remoteManagement?.managed ?? false
        )
    }
    
    
    private func formatJamfDate(_ dateString: String?) -> String? {
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
    
    private func toggleDeviceDetails(_ device: SearchResult) {
        if expandedDeviceID == device.id {
            // Collapse if already expanded
            expandedDeviceID = nil
        } else {
            // Expand and load details if not already cached
            expandedDeviceID = device.id
            
            if deviceDetails[device.id] == nil {
                loadDeviceDetails(device)
            }
        }
    }
    
    private func loadDeviceDetails(_ device: SearchResult) {
        loadingDetailsForDevice = device.id
        
        Task {
            guard let token = authManager.getActionFramework().getCurrentToken() else {
                await MainActor.run {
                    loadingDetailsForDevice = nil
                }
                return
            }
            
            let (computerDetail, _) = await JamfProAPI().getComputerDetails(
                jssURL: authManager.jssURL,
                authToken: token,
                computerID: device.id
            )
            
            await MainActor.run {
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
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        HStack {
                            Text(device.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            StatusIndicator(
                                isConnected: device.isManaged,
                                text: device.isManaged ? "Managed" : "Unmanaged"
                            )
                        }
                        
                        Text("Serial: \(device.serialNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if !device.userFullName.isEmpty {
                            Text("User: \(device.userFullName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if !device.username.isEmpty {
                            Text("Username: \(device.username)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Model: \(device.model)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Expand/Collapse Icon
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(DesignSystem.Spacing.md)
                .background(Color.clear)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded details section
            if isExpanded {
                VStack(spacing: DesignSystem.Spacing.md) {
                    Divider()
                    
                    if isLoadingDetails {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading device details...")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        .padding(.vertical, DesignSystem.Spacing.lg)
                    } else if let details = deviceDetails {
                        ExpandedDeviceDetails(device: device, deviceDetails: details)
                    } else {
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Failed to load device details")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, DesignSystem.Spacing.lg)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.md)
            }
        }
        .background(Color.clear)
        .cornerRadius(DesignSystem.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

// MARK: - Expanded Device Details
struct ExpandedDeviceDetails: View {
    let device: SearchResult
    let deviceDetails: DetailedDeviceInfo
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Basic device information
            HStack(alignment: .top, spacing: DesignSystem.Spacing.lg) {
                // Left column - Device info
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Device Information")
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
        }
        .padding(DesignSystem.Spacing.md)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(DesignSystem.cornerRadius)
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