import XCTest
@testable import Jamf_Device_Manager

final class JamfProAPITests: XCTestCase {
    
    var mockAPI: MockJamfProAPI!
    
    override func setUpWithError() throws {
        mockAPI = MockJamfProAPI()
    }

    override func tearDownWithError() throws {
        mockAPI = nil
    }

    func testDataModelDecoding() {
        // Test ComputerSummary decoding
        let computerSummaryJSON = """
        {
            "id": 123,
            "name": "Test Computer",
            "serial_number": "ABC123",
            "udid": "123-456-789",
            "mac_address": "00:11:22:33:44:55"
        }
        """
        
        let computerSummaryData = Data(computerSummaryJSON.utf8)
        let computerSummary = try? JSONDecoder().decode(ComputerSummary.self, from: computerSummaryData)
        
        XCTAssertNotNil(computerSummary, "ComputerSummary should decode successfully")
        XCTAssertEqual(computerSummary?.id, 123, "ID should match")
        XCTAssertEqual(computerSummary?.name, "Test Computer", "Name should match")
        XCTAssertEqual(computerSummary?.serialNumber, "ABC123", "Serial number should match")
    }
    
    func testAdvancedSearchSummaryDecoding() {
        // Test AdvancedSearchSummary decoding
        let searchSummaryJSON = """
        {
            "id": 456,
            "name": "Test Search"
        }
        """
        
        let searchSummaryData = Data(searchSummaryJSON.utf8)
        let searchSummary = try? JSONDecoder().decode(AdvancedSearchSummary.self, from: searchSummaryData)
        
        XCTAssertNotNil(searchSummary, "AdvancedSearchSummary should decode successfully")
        XCTAssertEqual(searchSummary?.id, 456, "ID should match")
        XCTAssertEqual(searchSummary?.name, "Test Search", "Name should match")
    }
    
    func testComputerDashboardInfoDecoding() {
        // Test ComputerDashboardInfo decoding with actual API field names
        let dashboardInfoJSON = """
        {
            "id": 789,
            "name": "Test Dashboard Computer",
            "Serial_Number": "XYZ789",
            "Model": "MacBook Pro",
            "Operating_System_Version": "14.0",
            "Last_Check_in": "2025-06-25 10:30:00"
        }
        """
        
        let dashboardInfoData = Data(dashboardInfoJSON.utf8)
        let dashboardInfo = try? JSONDecoder().decode(ComputerDashboardInfo.self, from: dashboardInfoData)
        
        XCTAssertNotNil(dashboardInfo, "ComputerDashboardInfo should decode successfully")
        XCTAssertEqual(dashboardInfo?.id, 789, "ID should match")
        XCTAssertEqual(dashboardInfo?.name, "Test Dashboard Computer", "Name should match")
        XCTAssertEqual(dashboardInfo?.serialNumber, "XYZ789", "Serial number should match")
        XCTAssertEqual(dashboardInfo?.model, "MacBook Pro", "Model should match")
        XCTAssertEqual(dashboardInfo?.osVersion, "14.0", "OS version should match")
        XCTAssertNotNil(dashboardInfo?.lastCheckIn, "Last check-in date should be parsed")
    }
}

// MARK: - Mock API for Testing

class MockJamfProAPI {
    var shouldFailWithNetworkError = false
    var shouldFailWithAuthError = false
    var mockComputers: [ComputerSummary] = []
    
    func fetchComputers() async throws -> [ComputerSummary] {
        if shouldFailWithNetworkError {
            throw URLError(.networkConnectionLost)
        }
        
        if shouldFailWithAuthError {
            throw URLError(.userAuthenticationRequired)
        }
        
        return mockComputers
    }
}