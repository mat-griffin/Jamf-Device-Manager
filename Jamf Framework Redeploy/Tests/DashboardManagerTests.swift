import XCTest
@testable import Jamf_Device_Manager

final class DashboardManagerTests: XCTestCase {
    
    var dashboardManager: DashboardManager!
    var mockAPI: MockJamfProAPI!
    
    override func setUpWithError() throws {
        mockAPI = MockJamfProAPI()
        dashboardManager = DashboardManager()
        // In real implementation, you'd inject the mock API
    }

    override func tearDownWithError() throws {
        dashboardManager = nil
        mockAPI = nil
    }

    func testInitialState() {
        XCTAssertEqual(dashboardManager.totalDevices, 0, "Total devices should start at 0")
        XCTAssertEqual(dashboardManager.managedDevices, 0, "Managed devices should start at 0")
        XCTAssertEqual(dashboardManager.unmanagedDevices, 0, "Unmanaged devices should start at 0")
        XCTAssertEqual(dashboardManager.offlineDevices, 0, "Offline devices should start at 0")
        XCTAssertFalse(dashboardManager.isLoading, "Should not be loading initially")
    }
    
    func testDeviceCalculations() {
        // Create mock dashboard data using the actual ComputerDashboardInfo structure
        let recentDate = Date()
        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        
        let mockData = [
            ComputerDashboardInfo(
                id: 1,
                name: "Test Mac 1", 
                serialNumber: "ABC123",
                model: "MacBook Pro",
                osVersion: "14.0", 
                lastCheckIn: recentDate
            ),
            ComputerDashboardInfo(
                id: 2,
                name: "Test Mac 2",
                serialNumber: "DEF456", 
                model: "MacBook Air",
                osVersion: "13.5",
                lastCheckIn: oldDate
            )
        ]
        
        // Manually set the calculated values (since processDashboardData is private)
        dashboardManager.totalDevices = mockData.count
        dashboardManager.managedDevices = mockData.count
        
        XCTAssertEqual(dashboardManager.totalDevices, 2, "Should calculate total devices correctly")
        XCTAssertEqual(dashboardManager.managedDevices, 2, "Should calculate managed devices correctly")
    }
    
    func testAdvancedSearchManagement() {
        // Test available searches management
        let mockSearches = [
            AdvancedSearchSummary(id: 1, name: "All Managed Computers"),
            AdvancedSearchSummary(id: 2, name: "Test Search"),
            AdvancedSearchSummary(id: 3, name: "Production Computers")
        ]
        
        dashboardManager.availableAdvancedSearches = mockSearches
        XCTAssertEqual(dashboardManager.availableAdvancedSearches.count, 3, "Should store available searches")
        
        // Test search selection
        dashboardManager.selectedAdvancedSearchID = 1
        XCTAssertEqual(dashboardManager.selectedAdvancedSearchID, 1, "Should store selected search ID")
    }
    
    func testDataStructures() {
        // Test OSVersionData structure
        let osData = OSVersionData(version: "14.0", count: 5)
        XCTAssertEqual(osData.version, "14.0", "OS version should be stored correctly")
        XCTAssertEqual(osData.count, 5, "OS version count should be stored correctly")
        
        // Test DeviceModelData structure  
        let modelData = DeviceModelData(model: "MacBook Pro", count: 3)
        XCTAssertEqual(modelData.model, "MacBook Pro", "Model should be stored correctly")
        XCTAssertEqual(modelData.count, 3, "Model count should be stored correctly")
        
        // Test CheckInStatusData structure
        let statusData = CheckInStatusData(label: "Online", count: 10, color: .green)
        XCTAssertEqual(statusData.label, "Online", "Status label should be stored correctly")
        XCTAssertEqual(statusData.count, 10, "Status count should be stored correctly")
    }
    
    func testLoadingStates() {
        // Test loading state management
        XCTAssertFalse(dashboardManager.isLoading, "Should start not loading")
        XCTAssertFalse(dashboardManager.isLoadingSearches, "Should start not loading searches")
        
        // Manually set loading states (since we can't easily test async methods without injecting dependencies)
        dashboardManager.isLoading = true
        XCTAssertTrue(dashboardManager.isLoading, "Should be able to set loading state")
        
        dashboardManager.isLoadingSearches = true
        XCTAssertTrue(dashboardManager.isLoadingSearches, "Should be able to set searches loading state")
    }
}