//
//  Jamf_Framework_RedeployApp.swift
//  Jamf Device Manager
//
//  Created by Richard Mallion on 09/01/2023.
//  Updated by Mat Griffin on 18/06/2025.
//

import SwiftUI

@main
struct Jamf_Framework_RedeployApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @State private var showingSettings = false
    @State private var showingAbout = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .textSelection(.enabled)
                .frame(
                    minWidth: 600, maxWidth: .infinity,
                    minHeight: 450, maxHeight: .infinity)
                .sheet(isPresented: $showingSettings) {
                    SettingsView(authManager: authManager, isPresented: $showingSettings)
                        .textSelection(.enabled)
                        .frame(minWidth: 500, minHeight: 600)
                }
                .sheet(isPresented: $showingAbout) {
                    AboutView(isPresented: $showingAbout)
                        .textSelection(.enabled)
                }
                .onAppear {
                    if let window = NSApplication.shared.windows.first {
                        window.titlebarAppearsTransparent = false
                        window.titleVisibility = .visible
                    }
                }
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Jamf Device Manager") {
                    showingAbout = true
                }
            }
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    showingSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
