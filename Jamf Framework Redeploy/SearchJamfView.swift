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
    @State private var dashboardSearchModel: String? = nil
    @State private var dashboardSearchOSVersion: String? = nil
    @State private var showDashboardSearchInfo = false
    @State private var dashboardDeviceData: [ComputerDashboardInfo] = []
    @State private var dashboardReportName: String = ""
    
    // External search trigger
    var onExternalModelSearch: ((String) -> Void)?
    
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
                        
                        // Dashboard Search Info Section
                        if showDashboardSearchInfo {
                            CardContainer {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                                    HStack {
                                        if dashboardSearchModel != nil {
                                            Label("Dashboard Model Search", systemImage: "chart.bar.xaxis")
                                                .font(.headline)
                                                .foregroundColor(.blue)
                                        } else if dashboardSearchOSVersion != nil {
                                            Label("Dashboard OS Version Search", systemImage: "gear.circle")
                                                .font(.headline)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            showDashboardSearchInfo = false
                                            dashboardSearchModel = nil
                                            dashboardSearchOSVersion = nil
                                            dashboardReportName = ""
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.secondary)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                        if let model = dashboardSearchModel {
                                            Text("You clicked on '\(model)' from the Dashboard chart for the '\(dashboardReportName)' Jamf Advanced Computer search.")
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            
                                            Text("This search is limited to the \(dashboardDeviceData.count) devices from your selected Dashboard Advanced Search, not all devices in Jamf Pro. Only devices matching '\(model)' from that group are shown below.")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        } else if let osVersion = dashboardSearchOSVersion {
                                            Text("You clicked on 'macOS \(osVersion)' from the Dashboard chart for the '\(dashboardReportName)' Jamf Advanced Computer search.")
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            
                                            Text("This search is limited to the \(dashboardDeviceData.count) devices from your selected Dashboard Advanced Search, not all devices in Jamf Pro. Only devices running macOS \(osVersion) from that group are shown below.")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        
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
                                        .frame(maxWidth: .infinity)
                                        
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
                            
                            // Text version for copying all results
                            CardContainer {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                                    HStack {
                                        Label("All Search Results as Plain Text", systemImage: "doc.plaintext")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            copyAllSearchResults()
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "doc.on.doc")
                                                    .foregroundColor(.secondary)
                                                    .font(.system(size: 12, weight: .medium))
                                                Text("Copy All")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(6)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    ScrollView {
                                        Text(searchResultsText)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                            .textSelection(.enabled)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .frame(maxHeight: 200)
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DashboardModelSearch"))) { notification in
            if let data = notification.object as? [String: Any],
               let model = data["model"] as? String,
               let dashboardData = data["dashboardData"] as? [ComputerDashboardInfo],
               let reportName = data["reportName"] as? String {
                performDashboardModelSearch(model, dashboardData: dashboardData, reportName: reportName)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DashboardOSVersionSearch"))) { notification in
            if let data = notification.object as? [String: Any],
               let osVersion = data["osVersion"] as? String,
               let dashboardData = data["dashboardData"] as? [ComputerDashboardInfo],
               let reportName = data["reportName"] as? String {
                performDashboardOSVersionSearch(osVersion, dashboardData: dashboardData, reportName: reportName)
            }
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
    
    private var searchResultsText: String {
        var text = "Search Results (\(searchResults.count) devices)\n"
        
        if showDashboardSearchInfo {
            if let model = dashboardSearchModel {
                text += "Search Type: Dashboard Model Search\n"
                text += "Model: \(model)\n"
            } else if let osVersion = dashboardSearchOSVersion {
                text += "Search Type: Dashboard OS Version Search\n"
                text += "macOS Version: \(osVersion)\n"
            }
            text += "Advanced Search: \(dashboardReportName)\n"
            text += "Search Scope: Limited to \(dashboardDeviceData.count) devices from Dashboard Advanced Search\n"
        } else {
            text += "Search Query: \(searchQuery)\n"
            text += "Management Filter: \(managementFilter == .all ? "All Devices" : managementFilter == .managed ? "Managed Only" : "Unmanaged Only")\n"
        }
        
        text += "Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))\n\n"
        
        for (index, device) in searchResults.enumerated() {
            text += "Device \(index + 1):\n"
            text += "Name: \(device.name)\n"
            text += "Serial: \(device.serialNumber)\n"
            text += "Management State: \(device.isManaged ? "Managed" : "Unmanaged")\n"
            
            if !device.userFullName.isEmpty {
                text += "User: \(device.userFullName)\n"
            }
            
            if !device.username.isEmpty {
                text += "Username: \(device.username)\n"
            }
            
            text += "Model: \(device.model)\n"
            
            if let details = deviceDetails[device.id] {
                text += "Computer ID: \(device.id)\n"
                text += "Operating System: \(details.operatingSystem)\n"
                text += "Processor: \(details.processor)\n"
                text += "Memory: \(details.memory)\n"
                text += "Last Inventory: \(details.lastInventoryUpdate)\n"
                text += "Last Check-in: \(details.lastCheckIn)\n"
                
                if let location = details.computerDetail.location {
                    if let email = location.emailAddress, !email.isEmpty {
                        text += "Email: \(email)\n"
                    }
                    if let department = location.department, !department.isEmpty {
                        text += "Department: \(department)\n"
                    }
                    if let building = location.building, !building.isEmpty {
                        text += "Building: \(building)\n"
                    }
                }
            }
            
            text += "\n"
        }
        
        return text
    }
    
    private func copyAllSearchResults() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(searchResultsText, forType: .string)
    }
    
    // MARK: - Dashboard Model Search Integration
    
    func performDashboardModelSearch(_ model: String, dashboardData: [ComputerDashboardInfo], reportName: String) {
        dashboardSearchModel = model
        dashboardSearchOSVersion = nil
        dashboardDeviceData = dashboardData
        dashboardReportName = reportName
        showDashboardSearchInfo = true
        
        // Set up advanced search for model
        advancedSearchQuery = model
        searchModel = true
        searchSerial = false
        searchUser = false
        searchComputerName = false
        showAdvancedSearch = true
        
        // Clear existing results
        searchResults = []
        
        // Perform the dashboard-scoped search
        performDashboardScopedSearch()
    }
    
    func performDashboardOSVersionSearch(_ osVersion: String, dashboardData: [ComputerDashboardInfo], reportName: String) {
        dashboardSearchModel = nil
        dashboardSearchOSVersion = osVersion
        dashboardDeviceData = dashboardData
        dashboardReportName = reportName
        showDashboardSearchInfo = true
        
        // Set up advanced search for OS version
        advancedSearchQuery = osVersion
        searchModel = false
        searchSerial = false
        searchUser = false
        searchComputerName = false
        showAdvancedSearch = true
        
        // Clear existing results
        searchResults = []
        
        // Perform the dashboard-scoped search
        performDashboardScopedOSVersionSearch()
    }
    
    private func performDashboardScopedSearch() {
        isSearching = true
        searchProgress = 0.0
        
        Task {
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
            
            // Filter dashboard data to only devices matching the model
            let filteredDashboardData = dashboardDeviceData.filter { device in
                guard let deviceModel = device.model else { return false }
                return deviceModel.lowercased().contains(advancedSearchQuery.lowercased())
            }
            
            await MainActor.run {
                searchProgress = 0.5
            }
            
            // Convert dashboard data to search results and fetch detailed info
            var results: [SearchResult] = []
            
            // Get a fresh token for detailed API calls
            guard let freshToken = await authManager.getFreshToken() else {
                await MainActor.run {
                    isSearching = false
                    searchProgress = 0.0
                    alertTitle = "Authentication Error"
                    alertMessage = "Failed to get authentication token for detailed device information."
                    showAlert = true
                }
                return
            }
            
            let jamfAPI = JamfProAPI()
            let totalDevices = filteredDashboardData.count
            
            for (index, dashboardDevice) in filteredDashboardData.enumerated() {
                // Update progress
                await MainActor.run {
                    searchProgress = 0.5 + (Double(index) / Double(totalDevices)) * 0.5
                }
                
                // Fetch detailed computer information to get user data
                let (computerDetail, statusCode) = await jamfAPI.getComputerDetails(
                    jssURL: authManager.jssURL,
                    authToken: freshToken,
                    computerID: dashboardDevice.id
                )
                
                // Check if API call was successful
                guard let computerDetail = computerDetail, statusCode == 200 else {
                    print("⚠️ Failed to get detailed information for device ID \(dashboardDevice.id), status: \(statusCode ?? 0)")
                    continue // Skip this device if we can't get detailed info
                }
                
                // Extract user information from detailed data
                let username = computerDetail.location?.username ?? ""
                let userFullName = computerDetail.location?.realname ?? ""
                
                let searchResult = SearchResult(
                    id: dashboardDevice.id,
                    name: dashboardDevice.name,
                    serialNumber: dashboardDevice.serialNumber ?? "",
                    username: username,
                    userFullName: userFullName,
                    model: dashboardDevice.model ?? "Mac",
                    isManaged: true // Dashboard data is from managed devices
                )
                results.append(searchResult)
                
                // Pre-populate device details with full information from API
                let osInfo = computerDetail.hardware?.osName ?? "macOS"
                let osVersion = computerDetail.hardware?.osVersion ?? dashboardDevice.osVersion ?? ""
                let fullOSInfo = "\(osInfo) \(osVersion)".trimmingCharacters(in: .whitespaces)
                
                let processorInfo = computerDetail.hardware?.processorType ?? "Unknown Processor"
                let memoryInfo = computerDetail.hardware?.totalRAM.map { "\($0) MB" } ?? "Unknown"
                let storageInfo = computerDetail.hardware?.totalDisk.map { "\($0) GB" } ?? "N/A"
                
                let lastInventory = computerDetail.general.lastInventoryUpdate ?? dashboardDevice.lastCheckIn?.formatted() ?? "N/A"
                let lastCheckIn = computerDetail.general.lastContactTime ?? dashboardDevice.lastCheckIn?.formatted() ?? "N/A"
                let enrollmentDate = computerDetail.general.lastEnrolledDate ?? "N/A"
                
                deviceDetails[searchResult.id] = DetailedDeviceInfo(
                    computerDetail: computerDetail,
                    lastInventoryUpdate: lastInventory,
                    enrollmentDate: enrollmentDate,
                    operatingSystem: fullOSInfo,
                    processor: processorInfo,
                    memory: memoryInfo,
                    storage: storageInfo,
                    lastCheckIn: lastCheckIn
                )
            }
            
            await MainActor.run {
                isSearching = false
                searchProgress = 0.0
                searchResults = results
                
                if results.isEmpty {
                    alertTitle = "No Results Found"
                    alertMessage = "No devices found matching '\(advancedSearchQuery)' in the Dashboard data. This search is limited to the \(dashboardDeviceData.count) devices from the selected Advanced Search."
                    showAlert = true
                }
            }
        }
    }
    
    private func performDashboardScopedOSVersionSearch() {
        isSearching = true
        searchProgress = 0.0
        
        Task {
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
            
            // Filter dashboard data to only devices matching the OS version
            let filteredDashboardData = dashboardDeviceData.filter { device in
                guard let deviceOSVersion = device.osVersion else { return false }
                return deviceOSVersion.lowercased().contains(advancedSearchQuery.lowercased())
            }
            
            await MainActor.run {
                searchProgress = 0.5
            }
            
            // Convert dashboard data to search results and fetch detailed info
            var results: [SearchResult] = []
            
            // Get a fresh token for detailed API calls
            guard let freshToken = await authManager.getFreshToken() else {
                await MainActor.run {
                    isSearching = false
                    searchProgress = 0.0
                    alertTitle = "Authentication Error"
                    alertMessage = "Failed to get authentication token for detailed device information."
                    showAlert = true
                }
                return
            }
            
            let jamfAPI = JamfProAPI()
            let totalDevices = filteredDashboardData.count
            
            for (index, dashboardDevice) in filteredDashboardData.enumerated() {
                // Update progress
                await MainActor.run {
                    searchProgress = 0.5 + (Double(index) / Double(totalDevices)) * 0.5
                }
                
                // Fetch detailed computer information to get user data
                let (computerDetail, statusCode) = await jamfAPI.getComputerDetails(
                    jssURL: authManager.jssURL,
                    authToken: freshToken,
                    computerID: dashboardDevice.id
                )
                
                // Check if API call was successful
                guard let computerDetail = computerDetail, statusCode == 200 else {
                    print("⚠️ Failed to get detailed information for device ID \(dashboardDevice.id), status: \(statusCode ?? 0)")
                    continue // Skip this device if we can't get detailed info
                }
                
                // Extract user information from detailed data
                let username = computerDetail.location?.username ?? ""
                let userFullName = computerDetail.location?.realname ?? ""
                
                let searchResult = SearchResult(
                    id: dashboardDevice.id,
                    name: dashboardDevice.name,
                    serialNumber: dashboardDevice.serialNumber ?? "",
                    username: username,
                    userFullName: userFullName,
                    model: dashboardDevice.model ?? "Mac",
                    isManaged: true // Dashboard data is from managed devices
                )
                results.append(searchResult)
                
                // Pre-populate device details with full information from API
                let osInfo = computerDetail.hardware?.osName ?? "macOS"
                let osVersion = computerDetail.hardware?.osVersion ?? dashboardDevice.osVersion ?? ""
                let fullOSInfo = "\(osInfo) \(osVersion)".trimmingCharacters(in: .whitespaces)
                
                let processorInfo = computerDetail.hardware?.processorType ?? "Unknown Processor"
                let memoryInfo = computerDetail.hardware?.totalRAM.map { "\($0) MB" } ?? "Unknown"
                let storageInfo = computerDetail.hardware?.totalDisk.map { "\($0) GB" } ?? "N/A"
                
                let lastInventory = computerDetail.general.lastInventoryUpdate ?? dashboardDevice.lastCheckIn?.formatted() ?? "N/A"
                let lastCheckIn = computerDetail.general.lastContactTime ?? dashboardDevice.lastCheckIn?.formatted() ?? "N/A"
                let enrollmentDate = computerDetail.general.lastEnrolledDate ?? "N/A"
                
                deviceDetails[searchResult.id] = DetailedDeviceInfo(
                    computerDetail: computerDetail,
                    lastInventoryUpdate: lastInventory,
                    enrollmentDate: enrollmentDate,
                    operatingSystem: fullOSInfo,
                    processor: processorInfo,
                    memory: memoryInfo,
                    storage: storageInfo,
                    lastCheckIn: lastCheckIn
                )
            }
            
            await MainActor.run {
                isSearching = false
                searchProgress = 0.0
                searchResults = results
                
                if results.isEmpty {
                    alertTitle = "No Results Found"
                    alertMessage = "No devices found running macOS \(advancedSearchQuery) in the Dashboard data. This search is limited to the \(dashboardDeviceData.count) devices from the selected Advanced Search."
                    showAlert = true
                }
            }
        }
    }
    
    private func createMockComputerDetail(from dashboardDevice: ComputerDashboardInfo, username: String = "", userFullName: String = "", emailAddress: String = "") -> ComputerDetail {
        // Create a mock ComputerDetail from dashboard data
        // This is a simplified version just for display purposes
        let general = General(
            id: dashboardDevice.id,
            name: dashboardDevice.name,
            serialNumber: dashboardDevice.serialNumber,
            udid: nil,
            remoteManagement: RemoteManagement(managed: true, managementUsername: nil),
            lastInventoryUpdate: dashboardDevice.lastCheckIn?.formatted(),
            reportDate: dashboardDevice.lastCheckIn?.formatted(),
            lastContactTime: dashboardDevice.lastCheckIn?.formatted(),
            lastEnrolledDate: nil
        )
        
        let hardware = Hardware(
            model: dashboardDevice.model,
            modelIdentifier: nil,
            osName: "macOS",
            osVersion: dashboardDevice.osVersion,
            osBuild: nil,
            processorType: nil,
            processorArchitecture: nil,
            processorSpeed: nil,
            numberOfProcessors: nil,
            numberOfCores: nil,
            totalRAM: nil,
            totalDisk: nil,
            availableDisk: nil
        )
        
        let location = Location(
            username: username.isEmpty ? nil : username,
            realname: userFullName.isEmpty ? nil : userFullName,
            emailAddress: emailAddress.isEmpty ? nil : emailAddress,
            position: nil,
            phone: nil,
            department: nil,
            building: nil,
            room: nil
        )
        
        return ComputerDetail(
            general: general,
            location: location,
            hardware: hardware
        )
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
                    
                    Text(deviceSummaryText(device))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    // Copy button
                    Button(action: {
                        copyDeviceInfo()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12, weight: .medium))
                            Text("Copy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 60, height: 24)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Expand/Collapse Button
                    Button(action: onToggle) {
                        HStack(spacing: 4) {
                            Image(systemName: isExpanded ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12, weight: .medium))
                            Text(isExpanded ? "Hide" : "Show")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 60, height: 24)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(Color.white)
            
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
        .background(Color.white)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
    
    private func deviceSummaryText(_ device: SearchResult) -> String {
        var text = "Serial: \(device.serialNumber)\n"
        
        if !device.userFullName.isEmpty {
            text += "User: \(device.userFullName)\n"
        }
        
        if !device.username.isEmpty {
            text += "Username: \(device.username)\n"
        }
        
        text += "Model: \(device.model)"
        
        return text
    }
    
    private func copyDeviceInfo() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        var text = "\(device.name)\n"
        text += "Serial: \(device.serialNumber)\n"
        
        if !device.userFullName.isEmpty {
            text += "User: \(device.userFullName)\n"
        }
        
        if !device.username.isEmpty {
            text += "Username: \(device.username)\n"
        }
        
        text += "Model: \(device.model)\n"
        text += "Management State: \(device.isManaged ? "Managed" : "Unmanaged")"
        
        // Add detailed info if available
        if let details = deviceDetails {
            text += "\n\nDevice Information\n"
            text += "Computer ID: \(device.id)\n"
            text += "Serial Number: \(device.serialNumber)\n"
            text += "Management State: \(device.isManaged ? "Managed" : "Unmanaged")\n"
            
            if let location = details.computerDetail.location {
                if let email = location.emailAddress, !email.isEmpty {
                    text += "Email: \(email)\n"
                }
                if let department = location.department, !department.isEmpty {
                    text += "Department: \(department)\n"
                }
                if let building = location.building, !building.isEmpty {
                    text += "Building: \(building)\n"
                }
            }
            
            text += "\nHardware Specifications\n"
            text += "Operating System: \(details.operatingSystem)\n"
            text += "Processor: \(details.processor)\n"
            text += "Memory: \(details.memory)\n"
            text += "Model: \(device.model)\n"
            text += "Last Inventory: \(details.lastInventoryUpdate)\n"
            text += "Last Check-in: \(details.lastCheckIn)"
        }
        
        pasteboard.setString(text, forType: .string)
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
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
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
                }
                
                Spacer()
                
                // Right column - Hardware specs
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Hardware Specifications")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        InfoRow(label: "Operating System", value: deviceDetails.operatingSystem)
                        InfoRow(label: "Processor", value: deviceDetails.processor)
                        InfoRow(label: "Memory", value: deviceDetails.memory)
                        InfoRow(label: "Model", value: device.model)
                        InfoRow(label: "Last Inventory", value: deviceDetails.lastInventoryUpdate)
                        InfoRow(label: "Last Check-in", value: deviceDetails.lastCheckIn)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(DesignSystem.CornerRadius.md)
        .contextMenu {
            Button(action: {
                copyAllDeviceInfo()
            }) {
                Label("Copy All Device Information", systemImage: "doc.on.doc")
            }
        }
    }
    
    private func copyAllDeviceInfo() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        var text = "Device Information\n"
        text += "Computer ID: \(device.id)\n"
        text += "Serial Number: \(device.serialNumber)\n"
        text += "Management State: \(device.isManaged ? "Managed" : "Unmanaged")\n"
        
        if let location = deviceDetails.computerDetail.location {
            if let email = location.emailAddress, !email.isEmpty {
                text += "Email: \(email)\n"
            }
            if let department = location.department, !department.isEmpty {
                text += "Department: \(department)\n"
            }
            if let building = location.building, !building.isEmpty {
                text += "Building: \(building)\n"
            }
        }
        
        text += "\nHardware Specifications\n"
        text += "Operating System: \(deviceDetails.operatingSystem)\n"
        text += "Processor: \(deviceDetails.processor)\n"
        text += "Memory: \(deviceDetails.memory)\n"
        text += "Model: \(device.model)\n"
        text += "Last Inventory: \(deviceDetails.lastInventoryUpdate)\n"
        text += "Last Check-in: \(deviceDetails.lastCheckIn)"
        
        pasteboard.setString(text, forType: .string)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label): \(value)")
                .font(.caption)
                .foregroundColor(.primary)
                .textSelection(.enabled)
            
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