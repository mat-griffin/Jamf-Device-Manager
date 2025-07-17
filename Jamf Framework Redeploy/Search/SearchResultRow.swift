//
//  SearchResultRow.swift
//  Jamf Device Manager
//
//  Created by AI Assistant on 25/06/2025.
//  Extracted from SearchJamfView.swift
//

import SwiftUI

// MARK: - Search Result Row
struct SearchResultRow: View {
    let device: SearchResult
    let isExpanded: Bool
    let deviceDetails: DetailedDeviceInfo?
    let isLoadingDetails: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row content - restructured to allow text selection
            HStack(spacing: DesignSystem.Spacing.md) {
                // Device Icon
                Image(systemName: "desktopcomputer")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 40)
                
                // Device Info - Now selectable text
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .textSelection(.enabled)
                    
                    HStack(spacing: 12) {
                        Text("SN: \(device.serialNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                        
                        if !device.username.isEmpty {
                            Text("User: \(device.username)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }
                        
                        Text(device.isManaged ? "Managed" : "Unmanaged")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(device.isManaged ? .green : .orange)
                            .textSelection(.enabled)
                    }
                }
                
                Spacer()
                
                // Expand/Collapse Button - Only this area is clickable
                Button(action: onToggle) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Collapse" : "Expand")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if isLoadingDetails {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(DesignSystem.Spacing.md)
            
            // Expanded details
            if isExpanded {
                if let deviceDetails = deviceDetails {
                    DeviceDetailsView(device: device, deviceDetails: deviceDetails)
                } else if !isLoadingDetails {
                    HStack {
                        Text("No additional details available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                        Spacer()
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(Color.gray.opacity(0.05))
                }
            }
        }
        .background(Color.clear)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Device Details View
struct DeviceDetailsView: View {
    let device: SearchResult
    let deviceDetails: DetailedDeviceInfo
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.xl) {
            // Left column - General info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("General Information")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                
                InfoRow(label: "Computer ID", value: String(device.id))
                InfoRow(label: "Serial Number", value: device.serialNumber)
                InfoRow(label: "Management State", value: device.isManaged ? "Managed" : "Unmanaged")
                
                if let location = deviceDetails.computerDetail.location {
                    if let email = location.emailAddress, !email.isEmpty {
                        InfoRow(label: "Email", value: email)
                    }
                    if let department = location.department, !department.isEmpty {
                        InfoRow(label: "Department", value: department)
                    }
                    if let building = location.building, !building.isEmpty {
                        InfoRow(label: "Building", value: building)
                    }
                }
            }
            
            Spacer()
            
            // Right column - Hardware specs
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Hardware Specifications")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                
                InfoRow(label: "Operating System", value: deviceDetails.operatingSystem)
                InfoRow(label: "Processor", value: deviceDetails.processor)
                InfoRow(label: "Memory", value: deviceDetails.memory)
                InfoRow(label: "Model", value: device.model)
                InfoRow(label: "Last Inventory", value: deviceDetails.lastInventoryUpdate)
                InfoRow(label: "Last Check-in", value: deviceDetails.lastCheckIn)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
                .textSelection(.enabled)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}