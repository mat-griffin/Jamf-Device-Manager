//
//  SearchResultsView.swift
//  Jamf Device Manager
//
//  Created by AI Assistant on 25/06/2025.
//  Extracted from SearchJamfView.swift
//

import SwiftUI

// MARK: - Search Results View
struct SearchResultsView: View {
    let results: [SearchResult]
    @Binding var expandedDeviceID: Int?
    let deviceDetails: [Int: DetailedDeviceInfo]
    let loadingDetailsForDevice: Int?
    let onDeviceToggle: (SearchResult) -> Void
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Label("Search Results (\(results.count))", systemImage: "list.bullet")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                LazyVStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(results, id: \.id) { device in
                        SearchResultRow(
                            device: device,
                            isExpanded: expandedDeviceID == device.id,
                            deviceDetails: deviceDetails[device.id],
                            isLoadingDetails: loadingDetailsForDevice == device.id,
                            onToggle: { onDeviceToggle(device) }
                        )
                    }
                }
            }
        }
    }
}