//
//  iosApp.swift
//  ios
//
//  Created by Aaditya Munjal on 6/4/25.
//

import SwiftUI
import Firebase
import GoogleSignIn
import UIKit

// MARK: - Deep Link Handler
class DeepLinkHandler: ObservableObject {
    @Published var pendingGroupId: String?
    @Published var showJoinGroupView = false
    
    func handleDeepLink(_ url: URL) {
        print("🔗 Processing deep link: \(url)")
        
        var groupId: String?
        
        // Handle both ruhere://join/groupId and https://ru-here.vercel.app/join/groupId
        if url.scheme == "ruhere" {
            // Parse ruhere://join/groupId
            if url.host == "join",
               let lastComponent = url.pathComponents.last,
               !lastComponent.isEmpty,
               lastComponent != "/" {
                groupId = lastComponent
            }
        } else if url.scheme == "https" && url.host?.contains("ru-here.vercel.app") == true {
            // Parse https://ru-here.vercel.app/join/groupId
            let pathComponents = url.pathComponents
            if pathComponents.count >= 3 && pathComponents[1] == "join" {
                groupId = pathComponents[2]
            }
        }
        
        if let validGroupId = groupId, !validGroupId.isEmpty {
            print("📦 Extracted group ID: \(validGroupId)")
            self.pendingGroupId = validGroupId
            self.showJoinGroupView = true
        } else {
            print("❌ Invalid deep link format. Expected: ruhere://join/groupId or https://ru-here.vercel.app/join/groupId")
        }
    }
    
    func dismissJoinGroup() {
        showJoinGroupView = false
        pendingGroupId = nil
    }
}

@main
struct iosApp: App {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var deepLinkHandler = DeepLinkHandler()
    
    @State private var groupService: GroupService?
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        // Global UI appearance
        AppTheme.setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(getOrCreateGroupService())
                .environmentObject(deepLinkHandler)
                // Allow system to toggle light/dark; our colors adapt
                .onOpenURL { url in
                    print("📱 Received URL: \(url)")
                    
                    // Handle Google Sign-In URLs
                    if url.scheme?.contains("googleusercontent") == true {
                        GIDSignIn.sharedInstance.handle(url)
                        return
                    }
                    
                    // Handle RUHere deep links (both custom scheme and universal links)
                    if url.scheme == "ruhere" || 
                       (url.scheme == "https" && url.host?.contains("ru-here.vercel.app") == true) {
                        deepLinkHandler.handleDeepLink(url)
                    }
                }
        }
    }
    
    // Helper function to ensure we use the same GroupService instance
    private func getOrCreateGroupService() -> GroupService {
        if let existingService = groupService {
            return existingService
        } else {
            let newService = GroupService(authService: authService)
            groupService = newService
            return newService
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var groupService: GroupService
    @EnvironmentObject var deepLinkHandler: DeepLinkHandler
    
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
        .sheet(isPresented: $deepLinkHandler.showJoinGroupView) {
            if let groupId = deepLinkHandler.pendingGroupId {
                JoinGroupView(groupId: groupId)
                    .environmentObject(authService)
                    .environmentObject(groupService)
                    .onDisappear {
                        deepLinkHandler.dismissJoinGroup()
                    }
            }
        }
    }
}

struct MainAppView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var groupService: GroupService
    
    var body: some View {
        GeofenceView()
    }
}
