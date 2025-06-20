//
//  DashboardManager.swift
//  Jamf Device Manager
//
//  Created by AI Assistant
//

import Foundation
import SwiftUI

struct OSVersionData {
    let version: String
    let count: Int
}

struct DeviceModelData {
    let model: String
    let count: Int
}

struct CheckInStatusData {
    let label: String
    let count: Int
    let color: Color
}

@MainActor
class DashboardManager: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    @Published var totalDevices = 0
    @Published var managedDevices = 0
    
    @Published var osVersionData: [OSVersionData] = []
    @Published var deviceModelData: [DeviceModelData] = []
    @Published var checkInStatusData: [CheckInStatusData] = []
    
    // Caching (like jamfdata project)
    private var cachedDashboardData: [ComputerDashboardInfo] = []
    private var lastCacheUpdate: Date? = nil
    private var cachedSearchID: Int? = nil
    private let cacheLifetime: TimeInterval = 300 // 5 minutes
    
    // Advanced Search management
    @Published var availableAdvancedSearches: [AdvancedSearchSummary] = []
    @Published var filteredAdvancedSearches: [AdvancedSearchSummary] = []
    @Published var selectedAdvancedSearchID: Int? = nil // No default selection - user must choose
    @Published var isLoadingSearches = false
    @Published var currentSearchName = ""
    @Published var hasLoadedSearches = false
    
    // Filter to control which Advanced Searches are shown in the dropdown
    // This is now controlled from Settings panel
    
    private let jamfAPI = JamfProAPI()
    private var authManager: AuthenticationManager?
    
    init() {
        // Listen for dashboard filter changes from Settings
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("DashboardFilterChanged"),
            object: nil,
            queue: .main
        ) { _ in
            print("📊 Dashboard: Received DashboardFilterChanged notification - refreshing filter")
            Task { @MainActor in
                self.refreshAdvancedSearchFilter()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setAuthManager(_ authManager: AuthenticationManager) {
        self.authManager = authManager
        // Automatically load available searches when auth manager is set
        if authManager.isAuthenticated {
            loadAvailableAdvancedSearches()
        }
    }
    
    func loadData() {
        guard !isLoading else { return }
        // Only load data if a search is selected
        guard selectedAdvancedSearchID != nil else {
            print("📊 Dashboard: No Advanced Search selected - skipping data load")
            return
        }
        
        Task {
            await fetchDashboardData()
        }
    }
    
    func refreshData() {
        Task {
            await fetchDashboardData()
        }
    }
    
    func loadAvailableAdvancedSearches() {
        guard !isLoadingSearches else { return }
        
        Task {
            await fetchAvailableAdvancedSearches()
        }
    }
    
    func selectAdvancedSearch(_ searchID: Int) {
        selectedAdvancedSearchID = searchID
        
        // Clear cache if switching to different search
        if cachedSearchID != searchID {
            print("📊 Dashboard: Clearing cache for search ID change: \(cachedSearchID ?? -1) -> \(searchID)")
            cachedDashboardData = []
            lastCacheUpdate = nil
            cachedSearchID = nil
        }
        
        loadData() // Reload data with new selection
    }
    
    private func fetchDashboardData() async {
        isLoading = true
        error = nil
        
        // Reset all data arrays
        osVersionData = []
        deviceModelData = []
        checkInStatusData = []
        
        // Get authentication token and server details
        guard let authManager = authManager,
              !authManager.jssURL.isEmpty else {
            self.error = "Authentication required"
            isLoading = false
            return
        }
        
        _ = authManager.getActionFramework()
        
        // Get a fresh token (will refresh if needed)
        guard let token = await authManager.getFreshToken() else {
            self.error = "Failed to get authentication token. Please check Settings to re-authenticate."
            isLoading = false
            return
        }
        
        // Use Advanced Search to get accurate managed device counts
        await fetchDashboardDataUsingAdvancedSearch(token: token, jssURL: authManager.jssURL)
        
        isLoading = false
    }
    
    private func fetchAvailableAdvancedSearches() async {
        isLoadingSearches = true
        hasLoadedSearches = false
        
        guard let authManager = authManager else {
            isLoadingSearches = false
            return
        }
        
        // Get a fresh token (will refresh if needed)
        guard let token = await authManager.getFreshToken() else {
            print("📊 Dashboard: Failed to get fresh OAuth token for Advanced Searches")
            isLoadingSearches = false
            return
        }
        
        print("📊 Dashboard: Using fresh OAuth token to fetch Advanced Searches...")
        let (searches, statusCode) = await jamfAPI.getAllAdvancedSearches(jssURL: authManager.jssURL, authToken: token)
        
        if let status = statusCode, status == 200 {
            availableAdvancedSearches = searches
            // Apply filter to create filtered list for dropdown
            applyAdvancedSearchFilter()
            hasLoadedSearches = true
            print("📊 Dashboard: Loaded \(searches.count) available Advanced Searches")
            let filterText = authManager.dashboardSearchFilter
            print("📊 Dashboard: Filtered to \(filteredAdvancedSearches.count) searches based on filter: '\(filterText)'")
            
            // Log filtered search names for debugging
            for search in filteredAdvancedSearches.prefix(5) {
                print("📊 Dashboard: Filtered search - ID: \(search.id), Name: '\(search.name)'")
            }
            if filteredAdvancedSearches.count > 5 {
                print("📊 Dashboard: ... and \(filteredAdvancedSearches.count - 5) more filtered searches")
            }
        } else if let status = statusCode, status == 401 {
            print("📊 Dashboard: OAuth token authentication failed (HTTP 401)")
            print("📊 Dashboard: Forcing token refresh and retrying...")
            
            // Force a fresh token and retry
            if let freshToken = await authManager.getFreshToken() {
                print("📊 Dashboard: Retrying with newly refreshed OAuth token...")
                let (retrySearches, retryStatusCode) = await jamfAPI.getAllAdvancedSearches(jssURL: authManager.jssURL, authToken: freshToken)
                
                if let retryStatus = retryStatusCode, retryStatus == 200 {
                    availableAdvancedSearches = retrySearches
                    // Apply filter to create filtered list for dropdown
                    applyAdvancedSearchFilter()
                    hasLoadedSearches = true
                    print("📊 Dashboard: Successfully loaded \(retrySearches.count) Advanced Searches on retry")
                    let filterText = authManager.dashboardSearchFilter
                    print("📊 Dashboard: Filtered to \(filteredAdvancedSearches.count) searches based on filter: '\(filterText)'")
                } else {
                    print("📊 Dashboard: Still failed to load Advanced Searches on retry (HTTP \(retryStatusCode ?? 0))")
                    if let retryStatus = retryStatusCode, retryStatus == 403 {
                        print("📊 Dashboard: Access denied - API account needs 'Read Advanced Searches' permission")
                    }
                }
            } else {
                print("📊 Dashboard: Failed to get fresh token for retry")
            }
        } else if let status = statusCode, status == 403 {
            print("📊 Dashboard: Access denied (HTTP 403)")
            print("📊 Dashboard: API account needs 'Read Advanced Searches' permission in Jamf Pro")
        } else {
            print("📊 Dashboard: Failed to load Advanced Searches (HTTP \(statusCode ?? 0))")
        }
        
        isLoadingSearches = false
    }
    
    // Public method to refresh the filter when settings change
    func refreshAdvancedSearchFilter() {
        print("📊 Dashboard: Refreshing Advanced Search filter...")
        applyAdvancedSearchFilter()
    }
    
    private func applyAdvancedSearchFilter() {
        guard let authManager = authManager else {
            filteredAdvancedSearches = availableAdvancedSearches
            return
        }
        
        let filterText = authManager.dashboardSearchFilter
        
        if filterText.isEmpty {
            // No filter - show all searches
            filteredAdvancedSearches = availableAdvancedSearches
            print("📊 Dashboard: No filter applied - showing all \(availableAdvancedSearches.count) searches")
        } else {
            // Debug: Log all available search names first
            print("📊 Dashboard: Applying filter '\(filterText)' to \(availableAdvancedSearches.count) available searches")
            for search in availableAdvancedSearches.prefix(10) {
                print("📊 Dashboard: Available search - ID: \(search.id), Name: '\(search.name)'")
            }
            if availableAdvancedSearches.count > 10 {
                print("📊 Dashboard: ... and \(availableAdvancedSearches.count - 10) more searches")
            }
            
            // Filter searches by name prefix
            filteredAdvancedSearches = availableAdvancedSearches.filter { search in
                let matches = search.name.hasPrefix(filterText)
                if matches {
                    print("📊 Dashboard: MATCH - '\(search.name)' starts with '\(filterText)'")
                }
                return matches
            }
            
            print("📊 Dashboard: Filter result - \(filteredAdvancedSearches.count) searches match filter '\(filterText)'")
            for filteredSearch in filteredAdvancedSearches {
                print("📊 Dashboard: Filtered search - ID: \(filteredSearch.id), Name: '\(filteredSearch.name)'")
            }
        }
    }
    
    private func fetchDashboardDataUsingAdvancedSearch(token: String, jssURL: String) async {
        print("📊 Dashboard: Using Advanced Search for accurate managed device data")
        
        // First get total devices count
        let (allComputers, allStatusCode) = await jamfAPI.getAllComputers(jssURL: jssURL, authToken: token, subset: "basic")
        
        if let statusCode = allStatusCode, statusCode != 200 {
            self.error = "Failed to fetch total device count (HTTP \(statusCode))"
            return
        }
        
        totalDevices = allComputers.count
        print("📊 Dashboard: Total devices: \(totalDevices)")
        
        // Get a fresh token for Advanced Search operations
        guard let authManager = authManager else {
            self.error = "Authentication manager not available"
            return
        }
        
        guard let freshToken = await authManager.getFreshToken() else {
            self.error = "Failed to get fresh authentication token"
            return
        }
        
        print("📊 Dashboard: Using fresh token for Advanced Search")
        
        // Get managed devices using selected Advanced Search
        guard let managedSearchID = selectedAdvancedSearchID else {
            print("📊 Dashboard: No Advanced Search selected, cannot load dashboard data")
            self.error = "Please select an Advanced Search from the dropdown to load dashboard data"
            return
        }
        
        // Check cache first (like jamfdata project)
        if let lastUpdate = lastCacheUpdate,
           cachedSearchID == managedSearchID,
           Date().timeIntervalSince(lastUpdate) < cacheLifetime,
           !cachedDashboardData.isEmpty {
            print("📊 Dashboard: Using cached data for search ID \(managedSearchID) (cache age: \(Int(Date().timeIntervalSince(lastUpdate)))s)")
            
            managedDevices = cachedDashboardData.count
            currentSearchName = availableAdvancedSearches.first(where: { $0.id == managedSearchID })?.name ?? "Advanced Search \(managedSearchID)"
            
            await processDashboardDataFromXML(cachedDashboardData)
            print("✅ Dashboard: Using CACHED data - \(managedDevices) managed devices")
            return
        }
        
        // Cache miss - fetch fresh data
        print("📊 Dashboard: Cache miss - fetching fresh data for search ID \(managedSearchID)")
        
        // FAST: Get all dashboard data in a single XML API call
        let (dashboardComputers, searchName, managedStatusCode) = await jamfAPI.getAdvancedSearchDashboardData(jssURL: jssURL, authToken: freshToken, searchID: managedSearchID)
        
        if let statusCode = managedStatusCode, statusCode != 200 {
            if statusCode == 401 {
                print("📊 Dashboard: Advanced Search 401 error - insufficient permissions")
                self.error = "Insufficient permissions to access the selected Advanced Search. Please check your Jamf Pro permissions or select a different Advanced Search."
                return
            } else {
                self.error = "Failed to fetch devices from Advanced Search (HTTP \(statusCode)). Please try selecting a different Advanced Search."
                return
            }
        }
        
        managedDevices = dashboardComputers.count
        
        // Update current search name
        currentSearchName = searchName ?? "Advanced Search \(managedSearchID)"
        
        print("📊 Dashboard: FAST XML - Advanced Search '\(currentSearchName)' loaded \(managedDevices) devices in 1 API call")
        
        // Update cache with fresh data
        cachedDashboardData = dashboardComputers
        lastCacheUpdate = Date()
        cachedSearchID = managedSearchID
        print("📊 Dashboard: Cached \(dashboardComputers.count) devices for search ID \(managedSearchID)")
        
        // Process all dashboard data from the single XML response (no additional API calls needed!)
        await processDashboardDataFromXML(dashboardComputers)
        
        print("✅ Dashboard: Using EXACT data from Advanced Search XML - \(managedDevices) managed devices")
    }
    
    
    // FAST: Process dashboard data from XML (no additional API calls needed!)
    private func processDashboardDataFromXML(_ computers: [ComputerDashboardInfo]) async {
        print("📊 Dashboard: FAST processing \(computers.count) devices from XML data (100% accuracy)")
        
        var osVersionCounts: [String: Int] = [:]
        var modelCounts: [String: Int] = [:]
        var checkInCounts = ["Last 24h": 0, "24-48h": 0, "48h+": 0, "Never": 0]
        
        let now = Date()
        let calendar = Calendar.current
        
        // Process all devices instantly (no API calls!)
        for computer in computers {
            // Process OS version
            if let osVersion = computer.osVersion, !osVersion.isEmpty {
                let normalizedVersion = normalizeOSVersion(osVersion)
                osVersionCounts[normalizedVersion, default: 0] += 1
            }
            
            // Process device model
            if let model = computer.model, !model.isEmpty {
                modelCounts[model, default: 0] += 1
            }
            
            // Process check-in status
            if let lastCheckIn = computer.lastCheckIn {
                let hours = calendar.dateComponents([.hour], from: lastCheckIn, to: now).hour ?? 0
                
                if hours < 24 {
                    checkInCounts["Last 24h"]! += 1
                } else if hours < 48 {
                    checkInCounts["24-48h"]! += 1
                } else {
                    checkInCounts["48h+"]! += 1
                }
            } else {
                checkInCounts["Never"]! += 1
            }
        }
        
        print("📊 Dashboard: XML processing complete - ALL \(computers.count) devices processed instantly")
        
        // Use exact counts from XML data (no scaling needed)
        osVersionData = osVersionCounts.map { version, count in
            OSVersionData(version: version, count: count)
        }.sorted { $0.version > $1.version }
        
        deviceModelData = modelCounts.map { model, count in
            DeviceModelData(model: model, count: count)
        }.sorted { $0.count > $1.count }
        
        // Create check-in status data
        checkInStatusData = [
            CheckInStatusData(label: "Last 24h", count: checkInCounts["Last 24h"]!, color: .green),
            CheckInStatusData(label: "24-48h", count: checkInCounts["24-48h"]!, color: .yellow),
            CheckInStatusData(label: "48h+", count: checkInCounts["48h+"]!, color: .red),
            CheckInStatusData(label: "Never", count: checkInCounts["Never"]!, color: .gray)
        ]
        
        print("📊 Dashboard: FAST RESULTS - OS versions: \(osVersionCounts.count), Models: \(modelCounts.count)")
        print("📊 Dashboard: Check-in status: Last 24h=\(checkInCounts["Last 24h"]!), 24-48h=\(checkInCounts["24-48h"]!), 48h+=\(checkInCounts["48h+"]!), Never=\(checkInCounts["Never"]!)")
        print("📊 Dashboard: Total devices in charts: OS=\(osVersionData.reduce(0) { $0 + $1.count }), Models=\(deviceModelData.reduce(0) { $0 + $1.count })")
    }
    
    
    private func normalizeOSVersion(_ version: String) -> String {
        // Handle cases like "15.5.0" -> "15.5" but keep "15.5.1" as "15.5.1"
        if version.hasSuffix(".0") {
            let components = version.components(separatedBy: ".")
            if components.count >= 3 && components[2] == "0" {
                return "\(components[0]).\(components[1])"
            }
        }
        return version
    }
    
}

// MARK: - Array Extension for Chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}