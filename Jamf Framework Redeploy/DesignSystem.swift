//
//  DesignSystem.swift
//  Jamf Device Manager
//
//

import SwiftUI

// MARK: - Design System
struct DesignSystem {
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
    
    // MARK: - Colors
    struct Colors {
        static let cardBackground = Color(NSColor.controlBackgroundColor)
        static let border = Color(NSColor.separatorColor)
        static let success = Color.green
        static let error = Color.red
        static let warning = Color.orange
        static let info = Color.blue
    }
    
    // MARK: - Corner Radius
    static let cornerRadius: CGFloat = 8
    static let shadowRadius: CGFloat = 4
    static let shadowOpacity: Double = 0.1
}

// MARK: - Section Header Component
struct SectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.cornerRadius)
        .shadow(radius: DesignSystem.shadowRadius, y: 2)
    }
}

// MARK: - Card Container Component
struct CardContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.cornerRadius)
        .shadow(radius: DesignSystem.shadowRadius, y: 2)
    }
}

// MARK: - Form Field Component
struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let helpText: String?
    
    init(label: String, placeholder: String, text: Binding<String>, isSecure: Bool = false, helpText: String? = nil) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.helpText = helpText
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            if let helpText = helpText {
                Text(helpText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Action Button Component
struct ActionButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let isLoading: Bool
    let isDisabled: Bool
    let width: CGFloat?
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case success
    }
    
    init(title: String, icon: String? = nil, style: ButtonStyle = .primary, isLoading: Bool = false, isDisabled: Bool = false, width: CGFloat? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.width = width
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .frame(width: width != nil ? width! - (DesignSystem.Spacing.lg * 2) : nil)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(DesignSystem.cornerRadius)
        }
        .frame(width: width)
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled || isLoading) ? 0.6 : 1.0)
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return .accentColor
        case .secondary:
            return Color.gray.opacity(0.2)
        case .destructive:
            return DesignSystem.Colors.error
        case .success:
            return DesignSystem.Colors.success
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive, .success:
            return .white
        case .secondary:
            return .primary
        }
    }
}

// MARK: - Status Indicator Component
struct StatusIndicator: View {
    let isConnected: Bool
    let text: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Circle()
                .fill(isConnected ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                .frame(width: 8, height: 8)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(isConnected ? DesignSystem.Colors.success : DesignSystem.Colors.error)
        }
    }
}

// MARK: - Device Info Card Component
struct DeviceInfoCard: View {
    let serialNumber: String
    let isManaged: Bool
    let computerID: Int
    let userFullName: String?
    let username: String?
    let userEmail: String?
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Label("Device Information", systemImage: "info.circle")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    DeviceInfoRow(label: "Serial Number", value: serialNumber)
                    DeviceInfoRow(label: "Computer ID", value: String(computerID))
                    
                    // User Information Section
                    if userFullName != nil || username != nil || userEmail != nil {
                        Divider()
                        
                        if let fullName = userFullName, !fullName.isEmpty {
                            DeviceInfoRow(label: "Full Name", value: fullName)
                        }
                        
                        if let user = username, !user.isEmpty {
                            DeviceInfoRow(label: "Username", value: user)
                        }
                        
                        if let email = userEmail, !email.isEmpty {
                            DeviceInfoRow(label: "Email", value: email)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Management State:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        StatusIndicator(
                            isConnected: isManaged,
                            text: isManaged ? "Managed" : "Unmanaged"
                        )
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Device Info Row Component
struct DeviceInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Empty State View Component
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - MacOS-Style Button Components
struct MacOSPrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    init(title: String, icon: String? = nil, isLoading: Bool = false, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .frame(minWidth: 120)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(.blue)
            .foregroundColor(.white)
            .cornerRadius(DesignSystem.cornerRadius)
        }
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled || isLoading) ? 0.6 : 1.0)
        .buttonStyle(PlainButtonStyle())
    }
}

struct MacOSSecondaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    init(title: String, icon: String? = nil, isLoading: Bool = false, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .frame(minWidth: 120)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(DesignSystem.cornerRadius)
        }
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled || isLoading) ? 0.6 : 1.0)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - MacOS Card Component
struct MacOSCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                .stroke(DesignSystem.Colors.border, lineWidth: 0.5)
        )
    }
}

// MARK: - MacOS Toolbar Component
struct MacOSToolbar: View {
    @Binding var selectedTab: Int
    let tabItems: [(title: String, icon: String)]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabItems.enumerated()), id: \.offset) { index, item in
                Button(action: {
                    selectedTab = index
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: item.icon)
                            .font(.system(size: 13))
                        Text(item.title)
                            .font(.system(size: 13))
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(selectedTab == index ? Color.accentColor.opacity(0.15) : Color.clear)
                    .foregroundColor(selectedTab == index ? .accentColor : .secondary)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                
                if index < tabItems.count - 1 {
                    Spacer().frame(width: DesignSystem.Spacing.sm)
                }
            }
        }
    }
}