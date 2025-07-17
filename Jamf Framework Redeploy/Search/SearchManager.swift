//
//  SearchManager.swift
//  Jamf Device Manager
//
//  Created by AI Assistant on 25/06/2025.
//  Extracted from SearchJamfView.swift
//

import Foundation

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
        return !isSearching
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
        let (allComputers, _) = await jamfAPI.getAllComputers(
            jssURL: authManager.jssURL,
            authToken: token,
            subset: "basic"
        )
        
        searchProgress = 0.3
        
        var results: [SearchResult] = []
        let totalComputers = allComputers.count
        var processedCount = 0
        
        for computer in allComputers {
            // Check if search was cancelled
            if Task.isCancelled { return }
            
            // Get detailed info for advanced filtering
            let (detail, _) = await jamfAPI.getComputerDetails(
                jssURL: authManager.jssURL,
                authToken: token,
                computerID: computer.id
            )
            
            processedCount += 1
            searchProgress = 0.3 + (0.6 * Double(processedCount) / Double(totalComputers))
            
            if let detail = detail {
                let isManaged = detail.general.remoteManagement?.managed ?? false
                let username = detail.location?.username ?? ""
                let userFullName = detail.location?.realname ?? ""
                let model = detail.hardware?.model ?? "Unknown"
                let computerName = detail.general.name
                let serialNumber = detail.general.serialNumber
                
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
                
                if matchesSearch && shouldInclude {
                    results.append(SearchResult(
                        id: computer.id,
                        name: computerName,
                        serialNumber: serialNumber,
                        username: username,
                        userFullName: userFullName,
                        model: model,
                        isManaged: isManaged
                    ))
                }
            }
            
            // Small delay to prevent overwhelming the API
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        searchProgress = 1.0
        searchResults = results
    }
}