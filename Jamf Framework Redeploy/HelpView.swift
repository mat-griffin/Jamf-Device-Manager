//
//  HelpView.swift
//  Jamf Device Manager
//
//

import SwiftUI

struct HelpView: View {
    @Binding var isPresented: Bool
    @State private var selectedSection = 0
    
    private let helpSections = [
        ("Getting Started", "questionmark.circle"),
        ("Dashboard", "chart.bar"),
        ("CSV Format", "doc.text"),
        ("Jamf Pro API Setup", "key"),
        ("Troubleshooting", "wrench.and.screwdriver"),
        ("App Info", "info.circle")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Sidebar with sections
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Text("Help")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .background(DesignSystem.Colors.cardBackground)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(DesignSystem.Colors.border),
                        alignment: .bottom
                    )
                    
                    // Section List
                    VStack(spacing: 4) {
                        ForEach(Array(helpSections.enumerated()), id: \.offset) { index, section in
                            Button(action: { selectedSection = index }) {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    Image(systemName: section.1)
                                        .frame(width: 16)
                                    Text(section.0)
                                    Spacer()
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.vertical, DesignSystem.Spacing.sm)
                                .background(selectedSection == index ? Color.accentColor.opacity(0.2) : Color.clear)
                                .foregroundColor(selectedSection == index ? .accentColor : .primary)
                                .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    
                    Spacer()
                }
                .frame(width: 200)
                .background(DesignSystem.Colors.cardBackground)
                .overlay(
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(DesignSystem.Colors.border),
                    alignment: .trailing
                )
                
                // Content Area
                GeometryReader { geometry in
                    ScrollView {
                        HStack {
                            Spacer()
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                                Group {
                                    switch selectedSection {
                                    case 0:
                                        GettingStartedContent()
                                    case 1:
                                        DashboardContent()
                                    case 2:
                                        CSVFormatContent()
                                    case 3:
                                        APISetupContent()
                                    case 4:
                                        TroubleshootingContent()
                                    case 5:
                                        AppInfoContent()
                                    default:
                                        GettingStartedContent()
                                    }
                                }
                            }
                            .frame(width: geometry.size.width * 0.85)
                            Spacer()
                        }
                        .padding(DesignSystem.Spacing.xl)
                    }
                }
                .background(Color(NSColor.textBackgroundColor))
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - Help Content Sections

struct GettingStartedContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("Getting Started")
                .font(.title)
                .fontWeight(.bold)
            
            HelpSection(title: "Initial Setup", icon: "gear") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("1. **Configure API Credentials**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("   • Click Settings (⚙️) or press ⌘,")
                    Text("   • Enter your Jamf Pro server URL")
                    Text("   • Add API Client ID and Secret")
                    Text("   • Click 'Test Connection' to verify")
                    
                    Text("2. **Choose Your Operation**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top)
                    Text("   • **Dashboard**: Fleet overview with statistics and charts")
                    Text("   • **Single Redeploy**: Individual device framework redeploy")
                    Text("   • **Mass Redeploy**: Bulk framework operations via CSV")
                    Text("   • **Manage & Lock**: Individual device management and locking")
                    Text("   • **Mass Manage & Lock**: Bulk management operations")
                }
            }
            
            HelpSection(title: "Quick Tips", icon: "lightbulb") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("• **Serial Numbers**: Use uppercase letters and numbers only")
                    Text("• **CSV Files**: Must have 'SerialNumber' column in header row")
                    Text("• **Authentication**: Green dot = connected, red dot = not authenticated")
                    Text("• **Progress**: Watch the progress bar during bulk operations")
                    Text("• **Results**: Click device serial numbers to open in Jamf Pro")
                }
            }
        }
    }
}

struct DashboardContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("Dashboard")
                .font(.title)
                .fontWeight(.bold)
            
            HelpSection(title: "Overview", icon: "chart.bar") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("The Dashboard provides a comprehensive view of your Jamf-managed device fleet using Advanced Computer Search groups.")
                    Text("• **Device Statistics**: Total managed devices and check-in status")
                    Text("• **macOS Version Distribution**: Bar chart showing OS versions")
                    Text("• **Device Model Distribution**: Donut chart showing hardware models")
                }
            }
            
            HelpSection(title: "Advanced Search Group Filter", icon: "magnifyingglass.circle") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                     Text("**How It Works:**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top)
                    Text("You can filter which Advanced Searches are available in the Dashboard by setting a prefix word filter. For example if in Jamf you have a number of Advanced Search groups all prefixed with the word Report: (e.g. Report: All Macs) then enter Report as you filter to just show groups starting with the word Report.")
                    Text("Note that the filter is case-sensitive.")

                    Text("**Setting Up the Filter:**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("1. Go to Settings (⚙️) or press ⌘,")
                    Text("2. Scroll to the 'Dashboard Settings' panel")
                    Text("3. Enter a prefix in 'Advanced Search Group Filter'")
                    Text("   • Example: \"Report:\" to show only searches starting with \"Report:\"")
                    Text("   • Leave blank to show all Advanced Searches")
                    Text("4. Click 'Save & Close'")
                    
                }
            }
            
            HelpSection(title: "Creating Organized Advanced Searches in Jamf Pro", icon: "plus.circle") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("**Recommended Naming Convention:**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Use consistent prefixes for related searches:")
                    Text("• **Dashboard:** - For dashboard-specific groups")
                    Text("• **Report:** - For reporting groups")
                    Text("• **Team:** - For department/team groups")
                    Text("• **Location:** - For site/location groups")
                    
                    Text("**Creating a Dashboard Search in Jamf Pro:**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top)
                    Text("1. Log into Jamf Pro as administrator")
                    Text("2. Go to Computers → Search Inventory → Advanced Search")
                    Text("3. Click 'New' to create a new search")
                    Text("4. Enter name with your chosen prefix (e.g., \"Dashboard: All Managed Devices\")")
                    Text("5. Add criteria to define your device group:")
                    Text("   • Management Status: Managed")
                    Text("   • Computer Group Membership: Specific groups")
                    Text("   • Operating System: macOS versions")
                    Text("   • Department: Specific departments")
                    Text("6. Set Display to show relevant fields:")
                    Text("   • Computer Name, Serial Number, Model")
                    Text("   • Operating System Version, Last Check-in")
                    Text("7. Save the search")
                    
                    Text("**Best Practices:**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top)
                    Text("• Use descriptive names after the prefix")
                    Text("• Keep search criteria focused for better performance")
                    Text("• Include fields needed for dashboard statistics")
                    Text("• Test searches before using in production")
                }
            }
            
            HelpSection(title: "Using the Dashboard", icon: "play.circle") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("**Step-by-Step:**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("1. **Select Search Group**: Choose an Advanced Search from the dropdown")
                    Text("2. **Load Data**: Click 'Refresh Data' or data loads automatically")
                    Text("3. **View Statistics**: Review device counts and check-in status")
                    Text("4. **Analyze Charts**: Hover over elements for detailed information")
                    Text("   • Bar chart: Hover bars for OS version details")
                    Text("   • Donut chart: Hover legend items to highlight segments")
                    
                    Text("**Performance Tips:**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top)
                    Text("• Dashboard data is cached for 5 minutes for faster loading")
                    Text("• Large search groups (1000+ devices) may take longer to load")
                    Text("• Use focused searches for better performance")
                    Text("• Refresh data when you need current information")
                }
            }
        }
    }
}

struct CSVFormatContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("CSV File Format")
                .font(.title)
                .fontWeight(.bold)
            
            HelpSection(title: "Required Format", icon: "doc.text") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("**Required Column:**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("• `SerialNumber` - Device serial number (case-sensitive)")
                    
                    Text("**Optional Columns:**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top)
                    Text("• `ComputerName` - Display name for the device")
                    Text("• `Notes` - Additional information or comments")
                }
            }
            
            HelpSection(title: "Sample CSV", icon: "doc.plaintext") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("**Basic Format:**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    CodeBlock(code: """
                    SerialNumber,ComputerName,Notes
                    C02XK1JKLVCG,John's MacBook Pro,Finance Department
                    FVFZM7LNKLHG,Jane's iMac,Marketing Team
                    G8WN0X9NHTD5,Bob's MacBook Air,Engineering
                    """)
                    
                    Text("**Minimal Format (Serial Only):**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top)
                    
                    CodeBlock(code: """
                    SerialNumber
                    C02XK1JKLVCG
                    FVFZM7LNKLHG
                    G8WN0X9NHTD5
                    """)
                }
            }
            
            HelpSection(title: "Format Rules", icon: "checkmark.shield") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("✅ **Valid Serial Numbers:**")
                    Text("   • C02XK1JKLVCG (12 characters, uppercase)")
                    Text("   • FVFZM7LNKLHG (alphanumeric only)")
                    
                    Text("❌ **Invalid Serial Numbers:**")
                        .padding(.top)
                    Text("   • c02xk1jklvcg (lowercase letters)")
                    Text("   • C02-XK1-JKLVCG (contains hyphens)")
                    Text("   • C02XK1 (too short)")
                }
            }
        }
    }
}

struct APISetupContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("API Setup Guide")
                .font(.title)
                .fontWeight(.bold)
            
            HelpSection(title: "Creating API Credentials", icon: "key") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("**Step 1: Create API Role**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("1. Log into Jamf Pro as administrator")
                    Text("2. Go to Settings → System → API Roles and Clients")
                    Text("3. Click 'New' under API Roles")
                    Text("4. Add these privileges:")
                    Text("   • Read Computers Check-in")
                    Text("   • Update Computers")
                    Text("   • Read Computers")
                    Text("   • Update User")
                    Text("   • Create Computers")
                    Text("   • Send Computer Remote Lock Command")
                    Text("   • Send Computer Unmanage Command")
                    
                    Text("**Step 2: Create API Client**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top)
                    Text("1. Click 'New' under API Clients")
                    Text("2. Enter a descriptive name")
                    Text("3. Select the API role created above")
                    Text("4. Set token lifetime to 30 minutes")
                    Text("5. Save and copy the Client ID and Secret")
                }
            }
            
            //HelpSection(title: "Required Permissions", icon: "lock.shield") {
               // VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                  //  Text("Your API client must have these permissions:")
                  //  Text("• **Read Computers** - Lookup device information")
                  //  Text("• **Update Computers** - Change management states")
                  //  Text("• **Send Computer Commands** - Framework redeploy and lock commands")
                  //  Text("• **View Computer Commands** - Monitor command status (optional)")
                //}
            //}
        }
    }
}

struct TroubleshootingContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("Troubleshooting")
                .font(.title)
                .fontWeight(.bold)
            
            HelpSection(title: "Authentication Issues", icon: "exclamationmark.triangle") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("**'Authentication Required' Error:**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("• Verify Server URL is correct")
                    Text("• Check Client ID and Secret")
                    Text("• Ensure API client is enabled in Jamf Pro")
                    Text("• Test connection in Settings")
                    
                    Text("**'Test Connection' Fails:**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top)
                    Text("• Check network connectivity")
                    Text("• Verify Jamf Pro server is accessible")
                    Text("• Confirm API credentials are correct")
                }
            }
            
            HelpSection(title: "Device Operation Issues", icon: "desktopcomputer") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("**'Computer not found' Error:**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("• Verify serial number(s)")
                    Text("• Ensure device is enrolled in Jamf Pro")
                    Text("• Use uppercase letters and numbers only")
                    
                    Text("**Framework Redeploy Fails:**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top)
                    Text("• Verify device is managed")
                    Text("• Verify API permissions")
                }
            }
            
            HelpSection(title: "CSV Import Problems", icon: "doc.badge.plus") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("**'File format not recognized':**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("• Ensure file has .csv extension")
                    Text("• Save as UTF-8 encoded CSV")
                    
                    Text("**'SerialNumber column not found':**")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top)
                    Text("• Add header row with 'SerialNumber'")
                    Text("• Remove any hidden characters")
                }
            }
        }
    }
}

struct AppInfoContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("App Information")
                .font(.title)
                .fontWeight(.bold)
            
            HelpSection(title: "Credits & Attribution", icon: "heart") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("The inspiration for this app is from the Jamf Framework Redeploy app by red5coder.")
                    
                    HStack {
                        Text("Github:")
                            .fontWeight(.medium)
                        Button(action: {
                            if let url = URL(string: "https://github.com/red5coder/Jamf-Framework-Redeploy") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Text("https://github.com/red5coder/Jamf-Framework-Redeploy")
                                .foregroundColor(.blue)
                                .underline()
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Click to open the original project on GitHub")
                    }
                }
            }
        }
    }
}

// MARK: - Helper Components

struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            content
                .padding(.leading, DesignSystem.Spacing.lg)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .shadow(radius: 2, y: 1)
    }
}

struct CodeBlock: View {
    let code: String
    
    var body: some View {
        Text(code)
            .font(.system(.caption, design: .monospaced))
            .padding(DesignSystem.Spacing.md)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView(isPresented: .constant(true))
            .frame(width: 800, height: 600)
    }
}