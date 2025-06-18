//
//  DesignSystem.swift
//  Jamf Framework Redeploy
//
//  Unified design system for consistent UI across the application
//

import SwiftUI

// MARK: - Design System Constants
struct DesignSystem {
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
    }
    
    // MARK: - Colors
    struct Colors {
        static let cardBackground = Color(.controlBackgroundColor)
        static let sectionBackground = Color(.windowBackgroundColor)
        static let border = Color.gray.opacity(0.3)
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
    }
}

// MARK: - Reusable UI Components

// MARK: - Section Header
struct SectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    
    init(icon: String, title: String, subtitle: String, iconColor: Color = .blue) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

// MARK: - Card Container
struct CardContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            content
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

// MARK: - Form Field
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
                .foregroundColor(.primary)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            }
            
            if let helpText = helpText {
                Text(helpText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Status Indicator
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

// MARK: - Action Button
struct ActionButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case success
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .accentColor
            case .secondary: return Color.clear
            case .destructive: return DesignSystem.Colors.error
            case .success: return DesignSystem.Colors.success
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .destructive, .success: return .white
            case .secondary: return .primary
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .secondary: return DesignSystem.Colors.border
            default: return nil
            }
        }
    }
    
    init(title: String, icon: String? = nil, style: ButtonStyle = .primary, isLoading: Bool = false, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
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
                        .foregroundColor(style.foregroundColor)
                } else if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .frame(minWidth: 120)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(DesignSystem.CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .stroke(style.borderColor ?? Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled || isLoading) ? 0.6 : 1.0)
    }
}

// MARK: - Device Info Card
struct DeviceInfoCard: View {
    let deviceName: String
    let serialNumber: String
    let isManaged: Bool
    let computerID: Int?
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Label("Device Information", systemImage: "laptopcomputer")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    InfoRow(label: "Computer Name", value: deviceName)
                    InfoRow(label: "Serial Number", value: serialNumber)
                    if let computerID = computerID {
                        InfoRow(label: "Computer ID", value: String(computerID))
                    }
                    
                    HStack {
                        Text("Management State:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        StatusIndicator(
                            isConnected: isManaged,
                            text: isManaged ? "Managed" : "Unmanaged"
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(icon: String, title: String, subtitle: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            if let actionTitle = actionTitle, let action = action {
                ActionButton(title: actionTitle, style: .primary, action: action)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.xl)
    }
} 