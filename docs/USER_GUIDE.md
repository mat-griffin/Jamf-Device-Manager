# Jamf Management Tool - User Guide

## Overview

The Jamf Management Tool is a comprehensive macOS application designed to simplify and streamline common Jamf Pro administrative tasks. It provides both single-device and bulk operations for framework management and device state changes.

## Features

### 🔧 Framework Management
- **Single Device Redeploy**: Deploy the Jamf framework to individual devices
- **Bulk Framework Redeploy**: Mass deploy framework to multiple devices via CSV import

### 🔒 Device Management State
- **Single Device Management**: Change management state and lock individual devices
- **Bulk Management Operations**: Mass management state changes with optional device locking

### 📊 Advanced Capabilities
- **CSV Import Support**: Drag-and-drop CSV file support for bulk operations
- **Real-time Progress Tracking**: Live progress indicators for bulk operations
- **Detailed Error Reporting**: Comprehensive error handling with specific failure reasons
- **Jamf Pro Integration**: Direct links to device records in Jamf Pro

## Getting Started

### Initial Setup

1. **Launch the Application**
   - Open "Jamf Management Tool" from Applications folder
   - The main interface will display with four primary tabs

2. **Configure Settings**
   - Click the **Settings** button (⚙️) in the top-right corner
   - Or use keyboard shortcut: `⌘,` (Command + Comma)

3. **Authentication Setup**
   - **Server URL**: Enter your Jamf Pro server URL (e.g., `https://yourcompany.jamfcloud.com`)
   - **Client ID**: Enter your API client ID from Jamf Pro
   - **Client Secret**: Enter your API client secret
   - Click **Test Connection** to verify credentials
   - Click **Save & Close** to store settings


## Using the Application

### Tab Overview

The application is organized into four main functional areas:

1. **Single Redeploy** - Individual device framework redeploy
2. **Mass Redeploy** - Bulk framework redeploy operations
3. **Manage & Lock** - Individual device management and locking
4. **Mass Manage & Lock** - Bulk management operations

### Single Device Operations

#### Framework Redeploy (Tab 1)

1. Navigate to the **Single Redeploy** tab
2. Enter the device's **Serial Number**
3. Click **Redeploy Framework**
4. Monitor the operation status in the alert dialog
5. Check device's management history in Jamf Pro for the InstallEnterpriseApplication command

#### Device Management & Lock (Tab 3)

1. Navigate to the **Manage & Lock** tab
2. Enter the device's **Serial Number**
3. Click **Get Device Info** to retrieve current management state
4. Review device information displayed
5. Choose desired action:
   - **Move to Managed**: Changes device to managed state
   - **Move to Unmanaged**: Removes management (with optional lock)
   - **Lock Device**: Sends lock command with random PIN

### Bulk Operations

#### Mass Framework Redeploy (Tab 2)

1. Navigate to the **Mass Redeploy** tab
2. **Import CSV File**:
   - Click **Import CSV** button, or
   - Drag and drop CSV file onto the drop zone
3. Review loaded computers in the list
4. Click **Start Mass Redeploy**
5. Monitor progress with the real-time progress bar
6. Review completion summary and individual device results

#### Mass Management & Lock (Tab 4)

1. Navigate to the **Mass Manage & Lock** tab
2. **Import CSV File** (same as above)
3. **Select Management Action**:
   - Choose **Move to Managed** or **Move to Unmanaged**
4. **Optional Device Locking** (for Unmanaged operations):
   - Enable **Lock Macs when moving to Unmanaged**
   - Each device will receive a unique 6-digit random PIN
5. Click **Start Mass Management**
6. Confirm the operation if locking is enabled
7. Monitor progress and review results

## CSV File Format

### Required Columns

Your CSV file must contain the following column:

| Column | Description | Required | Example |
|--------|-------------|----------|---------|
| `SerialNumber` | Device serial number | ✅ Yes | `C02XK1JKLVCG` |

### Optional Columns

| Column | Description | Required | Example |
|--------|-------------|----------|---------|
| `ComputerName` | Device name for display | ❌ No | `John's MacBook Pro` |
| `Notes` | Additional notes | ❌ No | `Finance Department` |

### Sample CSV Format

```csv
SerialNumber,ComputerName,Notes
C02XK1JKLVCG,John's MacBook Pro,Finance Department
C02YL2KMWVDH,Jane's iMac,Marketing Team
C02ZM3LNXWEI,Bob's MacBook Air,Engineering
```

### CSV Requirements

- File must have `.csv` extension
- First row must contain column headers
- `SerialNumber` column is mandatory
- Additional columns are ignored
- UTF-8 encoding recommended

## Understanding Results

### Status Indicators

Each device operation displays one of four status indicators:

- 🕐 **Pending**: Operation queued but not started
- 🔄 **Processing**: Operation currently in progress
- ✅ **Completed**: Operation completed successfully
- ❌ **Failed**: Operation failed (see error message)


## Troubleshooting

### Common Issues

**"Authentication Required" Error**
- Solution: Go to Settings (⌘,) and verify/re-enter API credentials

**CSV Import Fails**
- Check file format and ensure it has .csv extension
- Verify SerialNumber column exists in first row
- Try removing special characters from file name

**Devices Not Found**
- Verify serial numbers are correct and exist in Jamf Pro
- Check for extra spaces or formatting issues in CSV
- Ensure devices are enrolled in Jamf Pro

**Lock Commands Fail**
- Only managed devices can be locked
- Verify device is online and reachable
- Check that device supports lock commands (modern macOS)

**Slow Performance**
- Large CSV files (>100 devices) may take significant time
- Check network connection speed to Jamf Pro
- Consider breaking large operations into smaller batches

### Getting Help

1. **Check Error Messages**: Read specific error details in the application
2. **Verify Jamf Pro Access**: Test operations manually in Jamf Pro web interface
3. **Review API Permissions**: Ensure your API client has required permissions
4. **Contact Support**: Provide specific error messages and operation details

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘,` | Open Settings |
| `⌘W` | Close Window |
| `⌘Q` | Quit Application |