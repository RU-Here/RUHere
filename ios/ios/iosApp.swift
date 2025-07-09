//
//  iosApp.swift
//  ios
//
//  Created by Aaditya Munjal on 6/4/25.
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct iosApp: App {
    @StateObject private var authService = AuthenticationService()
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        ZStack {
            if authService.canProceed {
                MainAppView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8)),
                        removal: .opacity.combined(with: .scale(scale: 1.2))
                    ))
            } else {
                AuthenticationView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8)),
                        removal: .opacity.combined(with: .scale(scale: 1.2))
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.6), value: authService.canProceed)
    }
}

struct MainAppView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Main Map View
            GeofenceView()
                .tabItem {
                    Image(systemName: "location.fill")
                    Text("Map")
                }
                .tag(0)
            
            // Profile View
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(1)
        }
        .accentColor(.blue)
        .onAppear {
            // Set the tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
