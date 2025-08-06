//
//  iosApp.swift
//  ios
//
//  Created by Aaditya Munjal on 6/4/25.
//

import SwiftUI
import Firebase
import GoogleSignIn

// MARK: - Deep Link Handler
class DeepLinkHandler: ObservableObject {
    @Published var pendingGroupId: String?
    @Published var showJoinGroupView = false
    
    func handleDeepLink(_ url: URL) {
        print("🔗 Processing deep link: \(url)")
        
        // Parse ruhere://join/groupId
        if url.host == "join", 
           let groupId = url.pathComponents.last,
           !groupId.isEmpty,
           groupId != "/" {
            print("📦 Extracted group ID: \(groupId)")
            self.pendingGroupId = groupId
            self.showJoinGroupView = true
        } else {
            print("❌ Invalid deep link format. Expected: ruhere://join/groupId")
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
    @StateObject private var groupService = GroupService()
    @StateObject private var deepLinkHandler = DeepLinkHandler()
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(groupService)
                .environmentObject(deepLinkHandler)
                .onOpenURL { url in
                    print("📱 Received URL: \(url)")
                    
                    // Handle Google Sign-In URLs
                    if url.scheme?.contains("googleusercontent") == true {
                        GIDSignIn.sharedInstance.handle(url)
                        return
                    }
                    
                    // Handle RUHere deep links
                    if url.scheme == "ruhere" {
                        deepLinkHandler.handleDeepLink(url)
                    }
                }
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
