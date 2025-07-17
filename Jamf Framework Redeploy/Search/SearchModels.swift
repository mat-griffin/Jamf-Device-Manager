//
//  SearchModels.swift
//  Jamf Device Manager
//
//  Created by AI Assistant on 25/06/2025.
//  Extracted from SearchJamfView.swift
//

import Foundation

// MARK: - Data Models
struct SearchResult {
    let id: Int
    let name: String
    let serialNumber: String
    let username: String
    let userFullName: String
    let model: String
    let isManaged: Bool
}

struct DetailedDeviceInfo {
    let computerDetail: ComputerDetail
    let lastInventoryUpdate: String
    let enrollmentDate: String
    let operatingSystem: String
    let processor: String
    let memory: String
    let storage: String
    let lastCheckIn: String
}

enum ManagementFilter {
    case all
    case managed
    case unmanaged
}

enum SearchFieldType {
    case model
    case serial
    case user
    case computerName
}