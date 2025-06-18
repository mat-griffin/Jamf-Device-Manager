# CSV Format Specification - Jamf Device Manager

## Overview

This document specifies the CSV file format for bulk operations in Jamf Device Manager. The format supports framework redeploy and device management operations.

## File Requirements

- **File Extension**: `.csv` (required)
- **Character Encoding**: UTF-8
- **Header Row**: Must be present as first row


## Required Column

### SerialNumber
- **Column Name**: `SerialNumber` (case-sensitive, required)
- **Format**: Uppercase letters and numbers only
- **Length**: 8-12 characters
- **Examples**: `C02XK1JKLVCG`, `FVFZM7LNKLHG`, `G8WN0X9NHTD5`

## Optional Columns

### ComputerName
- **Column Name**: `ComputerName` (case-sensitive, optional)
- **Purpose**: Display name in application interface
- **Format**: Any text, use quotes if contains commas

### Notes
- **Column Name**: `Notes` (case-sensitive, optional)
- **Purpose**: Additional information or comments
- **Format**: Any text, use quotes if contains commas

## CSV Format Examples

### Standard Format
```csv
SerialNumber,ComputerName,Notes
C02XK1JKLVCG,John's MacBook Pro,Finance Department
FVFZM7LNKLHG,Jane's iMac,Marketing Team
G8WN0X9NHTD5,Bob's MacBook Air,Engineering
```

### Minimal Format (Serial Only)
```csv
SerialNumber
C02XK1JKLVCG
FVFZM7LNKLHG
G8WN0X9NHTD5
```