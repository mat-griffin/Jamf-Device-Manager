//
//  AboutView.swift
//  Jamf Device Manager
//
//  Created by AI Assistant
//

import SwiftUI

struct AboutView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // App Icon and Name
            VStack(spacing: DesignSystem.Spacing.md) {
                if let appIcon = NSApplication.shared.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 128, height: 128)
                        .cornerRadius(16)
                } else {
                    Image(systemName: "gear.badge")
                        .font(.system(size: 64))
                        .foregroundColor(.accentColor)
                        .frame(width: 128, height: 128)
                }
                
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("Jamf Device Manager")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
                .padding(.horizontal, DesignSystem.Spacing.xl)
            
            // Attribution Text
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Inspired by Jamf Framework Redeploy by red5coder")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                
                Text("Updated by Mat Griffin")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Original concept and framework by red5coder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        if let url = URL(string: "https://github.com/red5coder/Jamf-Framework-Redeploy") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Text("GitHub: red5coder/Jamf-Framework-Redeploy")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .underline()
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("Enhanced with additional features.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            
            Divider()
                .padding(.horizontal, DesignSystem.Spacing.xl)
            
            // Close Button
            HStack {
                Spacer()
                Button("Close") {
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                Spacer()
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(width: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView(isPresented: .constant(true))
    }
}