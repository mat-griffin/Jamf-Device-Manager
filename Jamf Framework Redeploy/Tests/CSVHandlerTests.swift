import XCTest
@testable import Jamf_Device_Manager

final class CSVHandlerTests: XCTestCase {
    
    var csvHandler: CSVHandler!
    var tempDirectory: URL!
    
    override func setUpWithError() throws {
        csvHandler = CSVHandler()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        csvHandler = nil
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
    }

    func testCSVParsing() throws {
        // Create a test CSV file
        let csvContent = """
        Serial Number,Computer Name,Notes
        ABC123,"John's MacBook",Test device 1
        DEF456,"Jane's MacBook",Test device 2
        GHI789,"Test MacBook",Test device 3
        """
        
        let csvFile = tempDirectory.appendingPathComponent("test.csv")
        try csvContent.write(to: csvFile, atomically: true, encoding: .utf8)
        
        // Test parsing
        let records = try csvHandler.parseCSV(from: csvFile)
        XCTAssertEqual(records.count, 3, "Should parse 3 records")
        XCTAssertEqual(records[0].serialNumber, "ABC123", "Should parse serial number correctly")
        XCTAssertEqual(records[0].computerName, "John's MacBook", "Should parse computer name correctly")
        XCTAssertEqual(records[1].serialNumber, "DEF456", "Should parse second serial number correctly")
    }
    
    func testEmptyCSVFile() throws {
        let csvFile = tempDirectory.appendingPathComponent("empty.csv")
        try "".write(to: csvFile, atomically: true, encoding: .utf8)
        
        XCTAssertThrowsError(try csvHandler.parseCSV(from: csvFile)) { error in
            XCTAssertTrue(error is CSVError, "Should throw CSVError")
            if let csvError = error as? CSVError {
                switch csvError {
                case .emptyFile:
                    break // This is expected
                default:
                    XCTFail("Should be emptyFile error, got: \(csvError)")
                }
            }
        }
    }
    
    func testInvalidCSVFormat() throws {
        let csvContent = """
        ABC123,Computer 1,Notes 1
        ,Computer 2,Notes 2
        XYZ789,Computer 3,Notes 3
        """
        
        let csvFile = tempDirectory.appendingPathComponent("invalid.csv")
        try csvContent.write(to: csvFile, atomically: true, encoding: .utf8)
        
        // Should skip invalid rows but parse valid ones
        let records = try csvHandler.parseCSV(from: csvFile)
        XCTAssertEqual(records.count, 2, "Should parse valid records and skip invalid ones")
        XCTAssertEqual(records[0].serialNumber, "ABC123", "Should parse first valid record")
        XCTAssertEqual(records[1].serialNumber, "XYZ789", "Should parse second valid record")
    }
    
    func testStatusUpdates() {
        // Test status update functionality
        let record = ComputerRecord(serialNumber: "TEST123", computerName: "Test Computer", notes: "Test notes")
        csvHandler.computers = [record]
        
        // Update status to in progress
        csvHandler.updateStatus(for: record.id, status: .inProgress, error: nil, jamfComputerID: nil)
        XCTAssertEqual(csvHandler.computers[0].status, .inProgress, "Status should be updated to inProgress")
        
        // Update status to completed
        csvHandler.updateStatus(for: record.id, status: .completed, error: nil, jamfComputerID: 12345)
        XCTAssertEqual(csvHandler.computers[0].status, .completed, "Status should be updated to completed")
        XCTAssertEqual(csvHandler.computers[0].jamfComputerID, 12345, "Jamf computer ID should be set")
        
        // Update status to failed with error
        csvHandler.updateStatus(for: record.id, status: .failed, error: "Test error", jamfComputerID: nil)
        XCTAssertEqual(csvHandler.computers[0].status, .failed, "Status should be updated to failed")
        XCTAssertEqual(csvHandler.computers[0].errorMessage, "Test error", "Error message should be set")
    }
}