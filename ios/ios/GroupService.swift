import Foundation
import Combine

class GroupService: ObservableObject {
    @Published var groups: [UserGroup] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://ru-here-api.vercel.app/api/geofence"
    private let authService: AuthenticationService
    
    init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    func fetchGroups(for userId: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        let urlString = "\(baseURL)/allGroups/\(userId)"
        print("🔗 Fetching groups from: \(urlString)")
        print("👤 User ID: \(userId)")
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL: \(urlString)"
                self.isLoading = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        
        // Get current user's ID token for authorization
        do {
            if let idToken = try await authService.getCurrentUserIdToken() {
                print("🔑 Using ID Token for authentication: \(idToken.prefix(20))...")
                request.setValue(idToken, forHTTPHeaderField: "authorization")
            } else {
                print("❌ No ID token available")
                DispatchQueue.main.async {
                    self.errorMessage = "Authentication required"
                    self.isLoading = false
                }
                return
            }
        } catch {
            print("❌ Failed to get ID token: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Failed to authenticate: \(error.localizedDescription)"
                self.isLoading = false
            }
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self.errorMessage = "Invalid response format"
                    self.isLoading = false
                }
                return
            }
            
            print("📡 HTTP Status Code: \(httpResponse.statusCode)")
            print("📡 Response Headers: \(httpResponse.allHeaderFields)")
            
            if httpResponse.statusCode == 200 {
                // Print raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Raw API Response: \(responseString)")
                }
                
                let decoder = JSONDecoder()
                let apiGroups = try decoder.decode([APIGroup].self, from: data)
                
                print("✅ Successfully decoded \(apiGroups.count) groups")
                
                let mappedGroups = apiGroups.map { apiGroup in
                    UserGroup(
                        id: apiGroup.id,
                        name: apiGroup.name,
                        people: apiGroup.people.compactMap { apiPerson in
                            // Only include people who have a name
                            guard let personName = apiPerson.name, !personName.isEmpty else {
                                print("⚠️ Skipping person with ID \(apiPerson.id) - missing name")
                                return nil
                            }
                            return Person(
                                id: apiPerson.id,
                                name: personName,
                                areaCode: apiPerson.areaCode ?? "",
                                photoURL: apiPerson.photoURL ?? ""
                            )
                        },
                        emoji: apiGroup.emoji.isEmpty ? "🏠" : apiGroup.emoji,
                        admin: apiGroup.admin
                    )
                }
                
                print("🔄 About to update UI with \(mappedGroups.count) groups:")
                for group in mappedGroups {
                    print("   - \(group.name) (ID: \(group.id)) with \(group.people.count) people")
                }
                
                DispatchQueue.main.async {
                    self.groups = mappedGroups
                    self.isLoading = false
                    self.errorMessage = nil // Clear any previous errors
                    
                    print("✅ UI State Updated - groups count: \(self.groups.count)")
                    if self.groups.isEmpty {
                        print("👤 User is not part of any groups (after UI update)")
                    } else {
                        print("🎉 Groups updated in UI: \(self.groups.count) groups")
                        for group in self.groups {
                            print("   UI Group: \(group.name)")
                        }
                    }
                }
            } else if httpResponse.statusCode == 404 {
                // User not found or no groups found
                DispatchQueue.main.async {
                    self.groups = []
                    self.errorMessage = nil
                    self.isLoading = false
                    print("👤 No groups found for user")
                }
            } else if httpResponse.statusCode == 401 {
                // Authentication error
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ Authentication failed: \(responseString)")
                }
                
                DispatchQueue.main.async {
                    self.errorMessage = "Authentication failed. Please sign in again."
                    self.isLoading = false
                }
            } else if httpResponse.statusCode >= 500 {
                // Server error
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ Server error response: \(responseString)")
                }
                
                DispatchQueue.main.async {
                    self.errorMessage = "Server is temporarily unavailable. Please try again later."
                    self.isLoading = false
                }
            } else {
                // Other client errors
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ Error response body (Status \(httpResponse.statusCode)): \(responseString)")
                }
                
                DispatchQueue.main.async {
                    self.errorMessage = "Unable to load groups (Status: \(httpResponse.statusCode)). Please check your connection and try again."
                    self.isLoading = false
                }
            }
        } catch let decodingError as DecodingError {
            print("🔍 JSON Decoding Error: \(decodingError)")
            DispatchQueue.main.async {
                self.errorMessage = "Data format error: \(decodingError.localizedDescription)"
                self.isLoading = false
            }
        } catch {
            print("🌐 Network Error: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Network error: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func createGroup(name: String, emoji: String, adminUserId: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/addGroup") else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL"
            }
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Get current user's ID token for authorization
        do {
            if let idToken = try await authService.getCurrentUserIdToken() {
                request.setValue(idToken, forHTTPHeaderField: "authorization")
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Authentication required"
                }
                return false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to authenticate: \(error.localizedDescription)"
            }
            return false
        }
        
        let groupData = [
            "name": name,
            "emoji": emoji,
            "admin": adminUserId
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: groupData)
            request.httpBody = jsonData
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Refresh groups after successful creation
                await fetchGroups(for: adminUserId)
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create group"
                }
                return false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error creating group: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    func addUserToGroup(groupId: String, userId: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/addUsertoGroup") else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL"
            }
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Get current user's ID token for authorization
        do {
            if let idToken = try await authService.getCurrentUserIdToken() {
                request.setValue(idToken, forHTTPHeaderField: "authorization")
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Authentication required"
                }
                return false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to authenticate: \(error.localizedDescription)"
            }
            return false
        }
        
        let userData = [
            "groupId": groupId,
            "userId": userId
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userData)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Add user to group HTTP Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    // Refresh groups after successful addition
                    await fetchGroups(for: userId)
                    return true
                } else {
                    // Print response body for error cases
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("❌ Error response: \(responseString)")
                    }
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to join group"
                    }
                    return false
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Invalid response format"
                }
                return false
            }
        } catch {
            print("🌐 Network Error adding user to group: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Error joining group: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Admin Actions
    func removeUserFromGroup(groupId: String, userId: String, requesterId: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/removeUserFromGroup") else {
            DispatchQueue.main.async { self.errorMessage = "Invalid URL" }
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            if let idToken = try await authService.getCurrentUserIdToken() {
                request.setValue(idToken, forHTTPHeaderField: "authorization")
            } else {
                DispatchQueue.main.async { self.errorMessage = "Authentication required" }
                return false
            }
        } catch {
            DispatchQueue.main.async { self.errorMessage = "Failed to authenticate: \(error.localizedDescription)" }
            return false
        }

        let payload: [String: Any] = [
            "groupId": groupId,
            "userId": userId,
            "requesterId": requesterId
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                await fetchGroups(for: requesterId)
                return true
            } else {
                if let http = response as? HTTPURLResponse, let s = String(data: data, encoding: .utf8) { print("Remove user error (\(http.statusCode)): \(s)") }
                DispatchQueue.main.async { self.errorMessage = "Failed to remove member" }
                return false
            }
        } catch {
            DispatchQueue.main.async { self.errorMessage = "Network error: \(error.localizedDescription)" }
            return false
        }
    }

    func updateGroupInfo(groupId: String, name: String?, emoji: String?, requesterId: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/updateGroupInfo") else {
            DispatchQueue.main.async { self.errorMessage = "Invalid URL" }
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            if let idToken = try await authService.getCurrentUserIdToken() {
                request.setValue(idToken, forHTTPHeaderField: "authorization")
            } else {
                DispatchQueue.main.async { self.errorMessage = "Authentication required" }
                return false
            }
        } catch {
            DispatchQueue.main.async { self.errorMessage = "Failed to authenticate: \(error.localizedDescription)" }
            return false
        }

        var payload: [String: Any] = [
            "groupId": groupId,
            "requesterId": requesterId
        ]
        if let name = name { payload["name"] = name }
        if let emoji = emoji { payload["emoji"] = emoji }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                await fetchGroups(for: requesterId)
                return true
            } else {
                if let http = response as? HTTPURLResponse, let s = String(data: data, encoding: .utf8) { print("Update group error (\(http.statusCode)): \(s)") }
                DispatchQueue.main.async { self.errorMessage = "Failed to update group" }
                return false
            }
        } catch {
            DispatchQueue.main.async { self.errorMessage = "Network error: \(error.localizedDescription)" }
            return false
        }
    }

    func transferAdmin(groupId: String, newAdminId: String, requesterId: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/transferAdmin") else {
            DispatchQueue.main.async { self.errorMessage = "Invalid URL" }
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            if let idToken = try await authService.getCurrentUserIdToken() {
                request.setValue(idToken, forHTTPHeaderField: "authorization")
            } else {
                DispatchQueue.main.async { self.errorMessage = "Authentication required" }
                return false
            }
        } catch {
            DispatchQueue.main.async { self.errorMessage = "Failed to authenticate: \(error.localizedDescription)" }
            return false
        }

        let payload: [String: Any] = [
            "groupId": groupId,
            "newAdminId": newAdminId,
            "requesterId": requesterId
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                await fetchGroups(for: requesterId)
                return true
            } else {
                if let http = response as? HTTPURLResponse, let s = String(data: data, encoding: .utf8) { print("Transfer admin error (\(http.statusCode)): \(s)") }
                DispatchQueue.main.async { self.errorMessage = "Failed to transfer admin" }
                return false
            }
        } catch {
            DispatchQueue.main.async { self.errorMessage = "Network error: \(error.localizedDescription)" }
            return false
        }
    }
    func fetchGroupById(_ groupId: String) async -> UserGroup? {
        guard let url = URL(string: "\(baseURL)/group/\(groupId)") else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL"
            }
            return nil
        }
        
        var request = URLRequest(url: url)
        
        // Get current user's ID token for authorization
        do {
            if let idToken = try await authService.getCurrentUserIdToken() {
                request.setValue(idToken, forHTTPHeaderField: "authorization")
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Authentication required"
                }
                return nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to authenticate: \(error.localizedDescription)"
            }
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self.errorMessage = "Invalid response format"
                }
                return nil
            }
            
            print("📡 Fetch group by ID HTTP Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let apiGroup = try decoder.decode(APIGroup.self, from: data)
                
                let userGroup = UserGroup(
                    id: apiGroup.id,
                    name: apiGroup.name,
                    people: apiGroup.people.compactMap { apiPerson -> Person? in
                        guard let personName = apiPerson.name, !personName.isEmpty else {
                            return nil
                        }
                        return Person(
                            id: apiPerson.id,
                            name: personName,
                            areaCode: apiPerson.areaCode ?? "",
                            photoURL: apiPerson.photoURL ?? ""
                        )
                    },
                    emoji: apiGroup.emoji.isEmpty ? "🏠" : apiGroup.emoji,
                    admin: apiGroup.admin
                )
                
                print("✅ Successfully fetched group: \(userGroup.name)")
                return userGroup
            } else if httpResponse.statusCode == 404 {
                DispatchQueue.main.async {
                    self.errorMessage = "Group not found"
                }
                return nil
            } else {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ Error response: \(responseString)")
                }
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch group details"
                }
                return nil
            }
        } catch {
            print("🌐 Network Error fetching group: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Network error: \(error.localizedDescription)"
            }
            return nil
        }
    }
}

// MARK: - API Response Models
struct APIGroup: Codable {
    let id: String
    let name: String
    let emoji: String
    let admin: String
    let people: [APIPerson]
}

struct APIPerson: Codable {
    let id: String
    let name: String?
    let areaCode: String?
    let photoURL: String?
} 
