//
//  DashboardView.swift
//  Jamf Device Manager
//
//  Created by AI Assistant
//

import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var dashboardManager: DashboardManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedOSVersion: String? = nil
    @State private var selectedDeviceModel: String? = nil
    
    // Navigation callback for model search
    var onModelSearch: ((String, [ComputerDashboardInfo], String) -> Void)?
    
    // Navigation callback for OS version search
    var onOSVersionSearch: ((String, [ComputerDashboardInfo], String) -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                HStack {
                    Spacer()
                    mainContent(geometry: geometry)
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            dashboardManager.setAuthManager(authManager)
            // Don't automatically load data - let user select Advanced Search first
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                // Load available searches when authenticated
                dashboardManager.loadAvailableAdvancedSearches()
            }
        }
    }
    
    @ViewBuilder
    private func mainContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Header Section
            SectionHeader(
                icon: "chart.bar.fill",
                title: "Dashboard",
                subtitle: "Device fleet overview and statistics. View your managed device counts, operating system distribution, and hardware model breakdown by Advanced Computer groups.",
                iconColor: DesignSystem.Colors.info
            )
            
            // Advanced Search Control Panel
            advancedSearchControlPanel
            
            if dashboardManager.selectedAdvancedSearchID == nil {
                // Show selection prompt when no search is selected
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Select an Advanced Search")
                        .font(.headline)
                    
                    Text("Choose an Advanced Search from the dropdown above to load your dashboard data.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(DesignSystem.Spacing.xl)
            } else if dashboardManager.isLoading {
                loadingView
            } else if let error = dashboardManager.error {
                errorView(error: error)
            } else if dashboardManager.selectedAdvancedSearchID != nil && dashboardManager.managedDevices > 0 {
                dashboardContent
            } else {
                // Show selection prompt as fallback
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Select an Advanced Search")
                        .font(.headline)
                    
                    Text("Choose an Advanced Search from the dropdown above to load your dashboard data.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(DesignSystem.Spacing.xl)
            }
        }
        .frame(maxWidth: geometry.size.width * 0.8)
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading device statistics...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.xl)
    }
    
    @ViewBuilder
    private func errorView(error: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Unable to load dashboard data")
                .font(.headline)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                dashboardManager.refreshData()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.xl)
    }
    
    @ViewBuilder
    private var advancedSearchControlPanel: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Panel Header
                Label("Jamf Advanced Computer Searches", systemImage: "magnifyingglass.circle")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: DesignSystem.Spacing.lg) {
                    // Advanced Search Selection
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Select the Jamf Advanced Computer search group to use for the dashboard data. Large groups may time some time to load.")
                        .font(.caption)
                            .foregroundColor(.secondary)
                        Text("You can set a prefix word in the Settings to filter the number of groups shown as not all groups may cotain the relevant data to create statistics and charts.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !dashboardManager.filteredAdvancedSearches.isEmpty {
                            Picker("", selection: Binding(
                                get: { dashboardManager.selectedAdvancedSearchID },
                                set: { 
                                    if let searchID = $0 {
                                        dashboardManager.selectAdvancedSearch(searchID)
                                    }
                                }
                            )) {
                                Text("Select a Jamf Advanced Search...")
                                    .tag(Optional<Int>.none)
                                ForEach(dashboardManager.filteredAdvancedSearches) { search in
                                    Text("\(search.name) (ID: \(search.id))")
                                        .tag(Optional(search.id))
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                        } else {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                if dashboardManager.isLoadingSearches {
                                    HStack(spacing: DesignSystem.Spacing.sm) {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .controlSize(.small)
                                        Text("Loading Advanced Searches...")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                } else if dashboardManager.hasLoadedSearches {
                                    Text("No Advanced Searches available")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Click 'Load Searches' to view available Advanced Searches")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Control Buttons
                    HStack(spacing: DesignSystem.Spacing.md) {
                        // Load Searches Button
                        Button(action: {
                            dashboardManager.loadAvailableAdvancedSearches()
                        }) {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                if dashboardManager.isLoadingSearches {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.down.circle")
                                }
                                Text("Load Searches")
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .cornerRadius(DesignSystem.CornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(dashboardManager.isLoadingSearches)
                        .help("Load available Advanced Searches from Jamf Pro")
                        
                        // Refresh Data Button
                        Button(action: {
                            dashboardManager.refreshData()
                        }) {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                if dashboardManager.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text("Refresh Data")
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(DesignSystem.CornerRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(dashboardManager.isLoading)
                        .help("Refresh dashboard data using selected Advanced Search")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var dashboardContent: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            deviceStatisticsSection
            osVersionChartSection
            deviceModelChartSection
        }
    }
    
    @ViewBuilder
    private var deviceStatisticsSection: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Label("Device Statistics", systemImage: "chart.bar.doc.horizontal")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Device Count Statistics - Full width rows
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Managed Devices Count
                    HStack {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "checkmark.shield")
                                .foregroundColor(.green)
                                .frame(width: 20)
                            Text("Managed Devices:")
                                .fontWeight(.medium)
                        }
                        Spacer()
                        Text("\(dashboardManager.managedDevices)")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    
                    Divider()
                    
                    // Device Check-in Status
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Device Check-in Status:")
                                .fontWeight(.medium)
                        }
                        
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            ForEach(dashboardManager.checkInStatusData, id: \.label) { status in
                                HStack {
                                    Circle()
                                        .fill(status.color)
                                        .frame(width: 8, height: 8)
                                    Text(status.label)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(status.count)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(status.color)
                                }
                                .padding(.leading, 28) // Align with main text
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var osVersionChartSection: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Label("macOS Version Distribution", systemImage: "gear.circle")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if dashboardManager.osVersionData.isEmpty {
                    Text("No data available")
                        .foregroundColor(.secondary)
                        .frame(height: 200)
                } else {
                    osVersionChart
                }
            }
        }
    }
    
    @ViewBuilder
    private var osVersionChart: some View {
        Chart(dashboardManager.osVersionData, id: \.version) { item in
            BarMark(
                x: .value("Version", item.version),
                y: .value("Count", item.count)
            )
            .foregroundStyle(by: .value("Version", item.version))
            .opacity(selectedOSVersion == nil || selectedOSVersion == item.version ? 1.0 : 0.5)
            
            if let selectedOSVersion = selectedOSVersion, selectedOSVersion == item.version {
                RuleMark(x: .value("Version", item.version))
                    .foregroundStyle(.gray)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .font(.caption)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                AxisValueLabel()
                    .font(.caption)
            }
        }
        .modifier(ChartSelectionModifier(selectedOSVersion: $selectedOSVersion, osVersionData: dashboardManager.osVersionData))
        .chartOverlay { chartProxy in
            GeometryReader { geometry in
                // Clickable and hoverable overlay for OS version search
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let location = value.location
                                // Find which OS version was clicked based on tap location
                                for osData in dashboardManager.osVersionData {
                                    if let xPosition = chartProxy.position(forX: osData.version) {
                                        let barWidth = geometry.size.width / CGFloat(dashboardManager.osVersionData.count)
                                        let tapX = location.x
                                        
                                        // Check if tap is within this bar's bounds
                                        if abs(tapX - xPosition) < barWidth / 2 {
                                            // Trigger search immediately on click
                                            onOSVersionSearch?(osData.version, dashboardManager.cachedDashboardData, dashboardManager.currentSearchName)
                                            break
                                        }
                                    }
                                }
                            }
                    )
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            // Find which OS version is being hovered
                            for osData in dashboardManager.osVersionData {
                                if let xPosition = chartProxy.position(forX: osData.version) {
                                    let barWidth = geometry.size.width / CGFloat(dashboardManager.osVersionData.count)
                                    let hoverX = location.x
                                    
                                    // Check if hover is within this bar's bounds
                                    if abs(hoverX - xPosition) < barWidth / 2 {
                                        selectedOSVersion = osData.version
                                        break
                                    }
                                }
                            }
                        case .ended:
                            selectedOSVersion = nil
                        }
                    }
                
                if let selectedOSVersion = selectedOSVersion,
                   let selectedData = dashboardManager.osVersionData.first(where: { $0.version == selectedOSVersion }) {
                    
                    if let xPosition = chartProxy.position(forX: selectedOSVersion) {
                        VStack(alignment: .center, spacing: 4) {
                            Text("macOS \(selectedData.version)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text("\(selectedData.count) devices")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Click indicator
                            Text("Click to search")
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .opacity(0.8)
                        }
                        .padding(8)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.primary.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
                        .position(
                            x: xPosition,
                            y: 25
                        )
                        .allowsHitTesting(false)
                    }
                }
            }
        }
        .chartLegend(.hidden)
    }
    
    @ViewBuilder  
    private var deviceModelChartSection: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Label("Device Model Distribution", systemImage: "laptopcomputer.and.iphone")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if dashboardManager.deviceModelData.isEmpty {
                    Text("No data available")
                        .foregroundColor(.secondary)
                        .frame(height: 300)
                } else {
                    if #available(macOS 14.0, *) {
                        deviceModelChart
                    } else {
                        // Fallback bar chart for macOS 13.0
                        Chart(dashboardManager.deviceModelData, id: \.model) { item in
                            BarMark(
                                x: .value("Model", item.model),
                                y: .value("Count", item.count)
                            )
                            .foregroundStyle(.green)
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisValueLabel()
                                    .font(.caption)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisGridLine()
                                AxisValueLabel()
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    @available(macOS 14.0, *)
    private var deviceModelChart: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            HStack(spacing: DesignSystem.Spacing.xl) {
                // Donut Chart - Centered in available space
                HStack {
                    Spacer()
                    Chart(Array(dashboardManager.deviceModelData.enumerated()), id: \.element.model) { index, item in
                        SectorMark(
                            angle: .value("Count", item.count),
                            innerRadius: .ratio(0.5),
                            outerRadius: .ratio(0.9)
                        )
                        .foregroundStyle(colorForModelAtIndex(index))
                        .opacity(selectedDeviceModel == nil || selectedDeviceModel == item.model ? 1.0 : 0.5)
                    }
                    .frame(width: 280, height: 280)
                    .chartLegend(.hidden)
                    Spacer()
                }
                
                // Custom Legend - Scrollable list for many models
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Models")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            ForEach(Array(dashboardManager.deviceModelData.enumerated()), id: \.element.model) { index, item in
                                Button(action: {
                                    onModelSearch?(item.model, dashboardManager.cachedDashboardData, dashboardManager.currentSearchName)
                                }) {
                                    HStack(spacing: DesignSystem.Spacing.sm) {
                                        Circle()
                                            .fill(colorForModelAtIndex(index))
                                            .frame(width: 12, height: 12)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.model)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                            
                                            Text("\(item.count) devices")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        // Click indicator
                                        Image(systemName: "magnifyingglass")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .opacity(selectedDeviceModel == item.model ? 1.0 : 0.0)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 6)
                                    .background(selectedDeviceModel == item.model ? Color.accentColor.opacity(0.15) : Color.clear)
                                    .cornerRadius(6)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .onHover { isHovering in
                                    selectedDeviceModel = isHovering ? item.model : nil
                                }
                                .animation(.easeInOut(duration: 0.2), value: selectedDeviceModel)
                                .help("Click to search for \(item.model) devices")
                            }
                        }
                    }
                    .frame(maxHeight: 240)
                }
                
                Spacer()
            }
        }
        .frame(height: 300)
    }
    
    // Helper function to generate unique colors based on index (ensures no duplicates)
    private func colorForModelAtIndex(_ index: Int) -> Color {
        let colors: [Color] = [
            .blue, .green, .orange, .red, .purple, .pink, .yellow, .cyan,
            .brown, .indigo, .mint, .teal, Color(red: 0.5, green: 0.8, blue: 0.9), 
            Color(red: 0.9, green: 0.6, blue: 0.4), Color(red: 0.7, green: 0.5, blue: 0.8),
            Color(red: 0.8, green: 0.4, blue: 0.6), Color(red: 0.4, green: 0.8, blue: 0.6),
            Color(red: 0.6, green: 0.4, blue: 0.8), Color(red: 0.8, green: 0.8, blue: 0.4),
            Color(red: 0.4, green: 0.6, blue: 0.8)
        ]
        
        return colors[index % colors.count]
    }
    
    // Helper function for backward compatibility (keeping for potential future use)
    private func colorForModel(_ model: String) -> Color {
        // Find the index of this model in the data array
        if let index = dashboardManager.deviceModelData.firstIndex(where: { $0.model == model }) {
            return colorForModelAtIndex(index)
        }
        // Fallback to blue if not found
        return .blue
    }
    
}

struct DeviceCountCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
                
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(DesignSystem.CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct DashboardChartCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            content
        }
        .padding(DesignSystem.Spacing.md)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}

struct ChartSelectionModifier: ViewModifier {
    @Binding var selectedOSVersion: String?
    let osVersionData: [OSVersionData]
    
    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content
                .chartXSelection(value: $selectedOSVersion)
        } else {
            content
        }
    }
}

struct DeviceModelSelectionModifier: ViewModifier {
    @Binding var selectedDeviceModel: String?
    let deviceModelData: [DeviceModelData]
    
    func body(content: Content) -> some View {
        content // No additional interaction needed since chartAngleSelection handles it
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(dashboardManager: DashboardManager())
            .environmentObject(AuthenticationManager())
    }
}