//
//  ContentView.swift
//  google_marine_waste
//
//  Created by jong on 2025/5/5.
//

import SwiftUI

// Main TabView
struct MainTabView: View {
    @Binding var username: String
    @Binding var isLoggedIn: Bool
    @Binding var userAvatar: String?
    @Binding var userRole: String
    @Binding var userId: String
    @Binding var userPoints: Int
    
    @State private var selectedTab = 0 // Track the currently selected Tab
    @State private var resetDashboard = false
    @State private var resetWasteRecognition = false
    @State private var resetActivityList = false
    @State private var resetPointExchange = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard
            DashboardView(username: $username, isLoggedIn: $isLoggedIn, userAvatar: $userAvatar, reset: $resetDashboard, userRole: $userRole, userId: $userId, userPoints: $userPoints)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)

            // Waste Recognition Page
            WasteRecognitionView(reset: $resetWasteRecognition, userId: $userId)
                .tabItem {
                    Label("Waste Recognition", systemImage: "camera.viewfinder")
                }
                .tag(1)

            // Activity List Page
            ActivityListView(username: $username, reset: $resetActivityList, userId: $userId)
                .tabItem {
                    Label("Activity List", systemImage: "calendar")
                }
                .tag(2)

            // Point Exchange Page
            PointExchangeView(userPoints: $userPoints)
                .tabItem {
                    Label("Point Exchange", systemImage: "gift.fill")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .onChange(of: selectedTab) { newValue in
            // Trigger reset for the corresponding page when switching tabs
            resetDashboard = (newValue == 0)
            resetWasteRecognition = (newValue == 1)
            resetActivityList = (newValue == 2)
            resetPointExchange = (newValue == 3)
        }
    }
}




/*
// User Forum Page
struct ForumView: View {
    var body: some View {
        VStack {
            Text("User Forum Page")
                .font(.largeTitle)
                .padding()
        }
        .navigationTitle("User Forum")
    }
}
*/
