import XCTest
@testable import Jamf_Device_Manager

final class AuthenticationManagerTests: XCTestCase {
    
    var authManager: AuthenticationManager!
    
    override func setUpWithError() throws {
        authManager = AuthenticationManager()
    }

    override func tearDownWithError() throws {
        authManager = nil
    }

    func testInitialAuthenticationState() {
        XCTAssertFalse(authManager.isAuthenticated, "Authentication manager should start in unauthenticated state")
        XCTAssertNil(authManager.authenticationError, "Should have no authentication error initially")
    }
    
    func testCredentialValidation() {
        // Test hasValidCredentials with empty credentials
        authManager.updateCredentials(jssURL: "", clientID: "", clientSecret: "", saveCredentials: false)
        XCTAssertFalse(authManager.hasValidCredentials, "Empty credentials should fail validation")
        
        // Test hasValidCredentials with partial credentials
        authManager.updateCredentials(jssURL: "https://example.jamfcloud.com", clientID: "", clientSecret: "", saveCredentials: false)
        XCTAssertFalse(authManager.hasValidCredentials, "Partial credentials should fail validation")
        
        // Test hasValidCredentials with complete credentials
        authManager.updateCredentials(jssURL: "https://example.jamfcloud.com", clientID: "test", clientSecret: "test", saveCredentials: false)
        XCTAssertTrue(authManager.hasValidCredentials, "Complete credentials should pass validation")
    }
    
    func testCredentialUpdates() {
        // Test credential updates
        authManager.updateCredentials(jssURL: "https://test.jamfcloud.com", clientID: "testID", clientSecret: "testSecret", saveCredentials: false)
        
        XCTAssertEqual(authManager.jssURL, "https://test.jamfcloud.com", "JSS URL should be updated")
        XCTAssertEqual(authManager.clientID, "testID", "Client ID should be updated")
        XCTAssertEqual(authManager.clientSecret, "testSecret", "Client secret should be updated")
        XCTAssertFalse(authManager.saveCredentials, "Save credentials flag should be updated")
    }
    
    func testDashboardFilterUpdates() {
        // Test dashboard filter updates
        authManager.updateDashboardSearchFilter("test-filter")
        XCTAssertEqual(authManager.dashboardSearchFilter, "test-filter", "Dashboard search filter should be updated")
    }
}