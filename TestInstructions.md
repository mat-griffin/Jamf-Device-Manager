# Unit Tests Setup Instructions

## Test Files Created

The following comprehensive unit test files have been created in `Jamf Framework Redeploy/Tests/`:

1. **JamfDeviceManagerTests.swift** - Main test suite template
2. **AuthenticationManagerTests.swift** - Tests for authentication logic
3. **JamfProAPITests.swift** - Tests for API data models and JSON parsing
4. **CSVHandlerTests.swift** - Tests for CSV parsing and file handling
5. **DashboardManagerTests.swift** - Tests for dashboard data management

## Setting Up Test Target in Xcode

To set up the test target in Xcode:

1. **Open Xcode project**: Open `Jamf Computer Manager.xcodeproj`

2. **Add Test Target**:
   - Select the project in the navigator
   - Click the "+" button at the bottom of the targets list
   - Choose "macOS" > "Unit Testing Bundle"
   - Name it "Jamf Device Manager Tests"
   - Set the target to be tested as "Jamf Device Manager"

3. **Add Test Files**:
   - Delete the default test file created by Xcode
   - Add all test files from `Jamf Framework Redeploy/Tests/` to the test target
   - Make sure to add them to the test target, not the main app target

4. **Configure Test Target**:
   - Set the same deployment target (macOS 14.6+)
   - Add `@testable import Jamf_Device_Manager` to test files
   - Ensure the test target has access to the main app's Swift module

## Running Tests

### In Xcode:
- Use `⌘+U` to run all tests
- Use `⌘+Ctrl+U` to run tests without building
- Click the diamond icon next to individual test methods to run specific tests

### Command Line:
```bash
xcodebuild test -project "Jamf Computer Manager.xcodeproj" -scheme "Jamf Device Manager" -destination "platform=macOS"
```

## Test Coverage

The tests cover:

### AuthenticationManager
- Initial state validation
- Credential validation logic
- Credential updates and persistence
- Dashboard filter management

### JamfProAPI
- Data model JSON decoding
- ComputerSummary parsing
- AdvancedSearchSummary parsing
- ComputerDashboardInfo with real API field names

### CSVHandler
- CSV file parsing with headers
- Error handling for empty/invalid files
- Status updates for deployment tracking
- File I/O operations

### DashboardManager
- Initial state management
- Advanced search management
- Data structure validation
- Loading state management

## Key Testing Patterns

1. **Mock Objects**: Created MockJamfProAPI for testing without network calls
2. **Error Testing**: Comprehensive error condition testing
3. **Data Validation**: JSON parsing with real API response formats
4. **State Management**: ObservableObject state changes
5. **File Operations**: Temporary directory usage for CSV testing

## Next Steps

1. Add more integration tests for API flows
2. Add UI tests for critical user workflows
3. Set up continuous integration with automated test runs
4. Add performance tests for large dataset handling
5. Consider adding snapshot tests for SwiftUI views

## Benefits

- **Regression Prevention**: Catch bugs before they reach users
- **Code Quality**: Enforce good architectural patterns
- **Documentation**: Tests serve as executable documentation
- **Refactoring Safety**: Confidence when making changes
- **API Contract Validation**: Ensure API responses parse correctly