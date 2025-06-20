# Jamf Device Manager - Development Context

## Project Overview
Jamf Device Manager is a comprehensive macOS application for managing Jamf Pro devices with both individual and bulk operations. Built with SwiftUI, it provides framework redeploys, management state changes, device locking, and device search capabilities.

## Current Status (v2.2.0)
- **Language**: Swift + SwiftUI
- **Platform**: macOS 14.6+
- **Architecture**: MVVM pattern with ObservableObject view models
- **Authentication**: OAuth 2.0 with Jamf Pro API
- **Interface**: 6-tab design (Dashboard, Jamf Search, Single Redeploy, Mass Redeploy, Manage & Lock, Mass Manage & Lock)

Note: this is a Mac app therefore ensure code is suitbale for Mac use with Keyboard and mouse not touch.

## Key Components
- `ContentView.swift` - Main application interface with tab navigation
- `AuthenticationManager.swift` - OAuth 2.0 authentication and credential management
- `JamfProApi.swift` - Jamf Pro API integration and communication
- `SearchJamfView.swift` - Device search and discovery functionality  
- `DashboardView.swift` - Device fleet statistics dashboard with charts
- `DashboardManager.swift` - Data fetching and processing for dashboard metrics
- Various specialized views for bulk operations and device management

## Testing Commands
- Build: Use Xcode build (⌘+B)
- No automated test suite currently configured

## Version 2.2.0 - Dashboard Implementation ✅ COMPLETED

### 📊 Dashboard Features (Implemented)
- **Device Statistics Panel**:
  - Total device count
  - Managed device count (from Jamf Pro API)
  - Unmanaged device count
  - Offline device count (7+ days since last contact)

- **Visual Charts** (Swift Charts framework):
  - macOS version distribution for managed devices (bar chart)
  - Device model distribution for managed devices (pie chart)

- **Technical Features**:
  - Statistical sampling for performance (up to 500 devices)
  - API rate limiting with batched requests
  - Real-time data from Jamf Pro detailed computer information
  - Responsive layout matching other application sections
  - Charts framework with backwards compatibility

### Implementation Details
- Uses `hardware.osVersion` and `hardware.model` from Jamf Pro API
- Filters charts to show only managed device data
- Consistent 80% width layout matching other sections
- Debug logging for troubleshooting data accuracy

## Next Steps
Ready for v2.3.0 planning when needed.