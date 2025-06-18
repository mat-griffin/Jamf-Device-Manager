//
//  JamfFunction.swift
//  Jamf Device Manager
//

import Foundation

// MARK: - Jamf Function Categories
enum JamfFunctionCategory: String, CaseIterable, Identifiable {
    case frameworkManagement = "Framework Management"
    case deviceManagement = "Device Management"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .frameworkManagement:
            return "gear.badge"
        case .deviceManagement:
            return "desktopcomputer"
        }
    }
    
    var functions: [JamfFunction] {
        switch self {
        case .frameworkManagement:
            return [.singleRedeploy, .bulkRedeploy]
        case .deviceManagement:
            return [.singleManagementState, .bulkManagementState]
        }
    }
}

// MARK: - Individual Jamf Functions
enum JamfFunction: String, CaseIterable, Identifiable {
    // Framework Management
    case singleRedeploy = "Single Device Redeploy"
    case bulkRedeploy = "Bulk Redeploy"
    
    // Device Management
    case singleManagementState = "Change Management State"
    case bulkManagementState = "Bulk Management State"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .singleRedeploy:
            return "desktopcomputer"
        case .bulkRedeploy:
            return "square.grid.3x3"
        case .singleManagementState:
            return "switch.2"
        case .bulkManagementState:
            return "list.bullet.rectangle"
        }
    }
    
    var description: String {
        switch self {
        case .singleRedeploy:
            return "Redeploy Jamf Framework to a single device"
        case .bulkRedeploy:
            return "Redeploy Jamf Framework to multiple devices via CSV"
        case .singleManagementState:
            return "Change device management state (Managed/Unmanaged)"
        case .bulkManagementState:
            return "Change management state for multiple devices via CSV"
        }
    }
    
    var category: JamfFunctionCategory {
        switch self {
        case .singleRedeploy, .bulkRedeploy:
            return .frameworkManagement
        case .singleManagementState, .bulkManagementState:
            return .deviceManagement
        }
    }
} 