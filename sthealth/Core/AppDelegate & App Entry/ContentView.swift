//
//  ContentView.swift
//  Sthealth
//
//  Created by Andrew Baggio on 6/01/25.
//

import SwiftUI

// Defines the tabs for type-safe, programmatic navigation.
enum AppTab {
    case capture, workshop, atlas
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab = .capture
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var workshopManager = WorkshopManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // Customize the appearance of the tab bar with glass effects.
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(Color.primaryBackground.opacity(0.95))
        
        // Apply blur effect for glass appearance
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundEffect = blurEffect
        
        // Customize tab bar item appearance
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.tertiaryText)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.tertiaryText),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.primaryAccent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.primaryAccent),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding || !authManager.isAuthenticated {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .onAppear {
                        print("🔍 ContentView: Showing onboarding. hasCompletedOnboarding: \(hasCompletedOnboarding), isAuthenticated: \(authManager.isAuthenticated)")
                    }
            } else {
                TabView(selection: $selectedTab) {
                    CaptureView()
                        .tabItem {
                            Label("Capture", systemImage: "sparkles")
                        }
                        .tag(AppTab.capture)
                        .onAppear {
                            print("🎉 ContentView: Showing main app. hasCompletedOnboarding: \(hasCompletedOnboarding), isAuthenticated: \(authManager.isAuthenticated)")
                        }
                    
                    WorkshopView()
                        .tabItem {
                            Label("Workshop", systemImage: "hammer.fill")
                        }
                        .tag(AppTab.workshop)

                    PsycheSpaceView()
                        .tabItem {
                            Label("Atlas", systemImage: "circle.grid.hex.fill")
                        }
                        .tag(AppTab.atlas)
                }
                .tint(.primaryAccent)
                .background(Color.primaryBackground)
                .sheet(isPresented: $workshopManager.showWorkshopView) {
                    NewWorkshopView()
                }
            }
        }
        .environmentObject(authManager)
    }
}
