//
//  SearchJamfView.swift
//  Jamf Device Manager
//
//  Created by Mat Griffin on 19/06/2025.
//  Refactored by AI Assistant on 25/06/2025.
//

import SwiftUI

struct SearchJamfView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var searchManager = SearchManager()
    @State private var expandedDeviceID: Int?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                HStack {
                    Spacer()
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Header Section
                        SectionHeader(
                            icon: "magnifyingglass",
                            title: "Search Jamf",
                            subtitle: "Search for devices in your Jamf Pro environment. Enter a serial number, computer name, or username to find device information.",
                            iconColor: DesignSystem.Colors.info
                        )
                        
                        // Search Input Section
                        SearchInputSection(searchManager: searchManager)
                        
                        // Advanced Search Section
                        if searchManager.showAdvancedSearch {
                            AdvancedSearchSection(searchManager: searchManager)
                        }
                        
                        // Search Results
                        if !searchManager.searchResults.isEmpty {
                            SearchResultsView(
                                results: searchManager.searchResults,
                                expandedDeviceID: $expandedDeviceID,
                                deviceDetails: searchManager.deviceDetails,
                                loadingDetailsForDevice: searchManager.loadingDetailsForDevice,
                                onDeviceToggle: toggleDeviceDetails
                            )
                        }
                    }
                    .frame(width: geometry.size.width * 0.8)
                    .animation(.easeInOut(duration: 0.3), value: searchManager.showAdvancedSearch)
                    Spacer()
                }
            }
        }
        .navigationTitle("Search Jamf")
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onDisappear {
            searchManager.cancelSearch()
        }
    }
    
    // MARK: - Private Methods
    
    private func toggleDeviceDetails(_ device: SearchResult) {
        if expandedDeviceID == device.id {
            expandedDeviceID = nil
        } else {
            expandedDeviceID = device.id
            if searchManager.deviceDetails[device.id] == nil {
                searchManager.loadDeviceDetails(device, authManager: authManager)
            }
        }
    }
}

// MARK: - Search Input Section
private struct SearchInputSection: View {
    @ObservedObject var searchManager: SearchManager
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Label("Simple Search", systemImage: "magnifyingglass.circle")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    TextField("Full serial number or username", text: $searchManager.searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            searchManager.performSimpleSearch(authManager: authManager)
                        }
                    
                    Text("Search by full serial number or exact username.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Management State Filter
                ManagementFilterSection(managementFilter: $searchManager.managementFilter)
                
                // Action Buttons
                HStack {
                    if searchManager.isSearching {
                        Button(action: searchManager.cancelSearch) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                Text("Cancel Search")
                            }
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        ActionButton(
                            title: "Search",
                            icon: "magnifyingglass",
                            style: .primary,
                            isLoading: false
                        ) {
                            searchManager.performSimpleSearch(authManager: authManager)
                        }
                        .disabled(searchManager.searchQuery.isEmpty)
                        
                        ActionButton(
                            title: searchManager.showAdvancedSearch ? "Hide Advanced" : "Advanced Search",
                            icon: "slider.horizontal.3",
                            style: .secondary,
                            isLoading: false
                        ) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                searchManager.showAdvancedSearch.toggle()
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Management Filter Section
private struct ManagementFilterSection: View {
    @Binding var managementFilter: ManagementFilter
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Management State Filter")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            HStack {
                // Custom segmented control
                HStack(spacing: 0) {
                    ManagementFilterButton(
                        title: "All Devices",
                        filter: .all,
                        currentFilter: managementFilter,
                        action: { managementFilter = .all }
                    )
                    
                    ManagementFilterButton(
                        title: "Managed Only",
                        filter: .managed,
                        currentFilter: managementFilter,
                        action: { managementFilter = .managed }
                    )
                    
                    ManagementFilterButton(
                        title: "Unmanaged Only",
                        filter: .unmanaged,
                        currentFilter: managementFilter,
                        action: { managementFilter = .unmanaged }
                    )
                }
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                Spacer()
            }
        }
    }
}

// MARK: - Management Filter Button
private struct ManagementFilterButton: View {
    let title: String
    let filter: ManagementFilter
    let currentFilter: ManagementFilter
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minWidth: 100, maxWidth: .infinity)
                .foregroundColor(currentFilter == filter ? .white : .primary)
                .background(currentFilter == filter ? Color.accentColor : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Advanced Search Section
private struct AdvancedSearchSection: View {
    @ObservedObject var searchManager: SearchManager
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Label("Advanced Search", systemImage: "slider.horizontal.3")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    TextField("Search term", text: $searchManager.advancedSearchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("Enter a search term and select which fields to search.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Search Field Options
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Search Fields")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        SearchFieldCheckbox(
                            title: "Model (M4, M1, MacBook Air, etc.)",
                            isSelected: $searchManager.searchModel,
                            isEnabled: searchManager.isFieldEnabled(.model)
                        )
                        
                        SearchFieldCheckbox(
                            title: "Partial Serial Number (e.g. K3)",
                            isSelected: $searchManager.searchSerial,
                            isEnabled: searchManager.isFieldEnabled(.serial)
                        )
                        
                        SearchFieldCheckbox(
                            title: "User (username, email, full name)",
                            isSelected: $searchManager.searchUser,
                            isEnabled: searchManager.isFieldEnabled(.user)
                        )
                        
                        SearchFieldCheckbox(
                            title: "Computer Name",
                            isSelected: $searchManager.searchComputerName,
                            isEnabled: searchManager.isFieldEnabled(.computerName)
                        )
                    }
                }
                
                // Progress Bar
                if searchManager.isSearching && searchManager.searchProgress > 0 {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        HStack {
                            Text("Searching...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(searchManager.searchProgress * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: min(max(searchManager.searchProgress, 0.0), 1.0))
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
                
                // Advanced Search Button
                HStack {
                    if searchManager.isSearching {
                        Button(action: searchManager.cancelSearch) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                Text("Cancel Search")
                            }
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        ActionButton(
                            title: "Advanced Search",
                            icon: "magnifyingglass.circle",
                            style: .secondary,
                            isLoading: false
                        ) {
                            searchManager.performAdvancedSearch(authManager: authManager)
                        }
                        .disabled(searchManager.advancedSearchQuery.isEmpty || !searchManager.hasValidAdvancedSearchFields())
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Search Field Checkbox
private struct SearchFieldCheckbox: View {
    let title: String
    @Binding var isSelected: Bool
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Button(action: { isSelected.toggle() }) {
                HStack(spacing: 8) {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .foregroundColor(isSelected ? .blue : .secondary)
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(isEnabled ? .primary : .secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!isEnabled)
            Spacer()
        }
    }
}