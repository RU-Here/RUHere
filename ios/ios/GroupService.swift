import Foundation
import Combine

class GroupService: ObservableObject {
    @Published var groups: [UserGroup] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://ru-here.vercel.app/api/geofence"
    
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
        request.setValue(apiKey, forHTTPHeaderField: "x-api-Key")
        
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
            
            if httpResponse.statusCode == 200 {
                // Print raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Raw API Response: \(responseString)")
                }
                
                let decoder = JSONDecoder()
                let apiGroups = try decoder.decode([APIGroup].self, from: data)
                
                print("✅ Successfully decoded \(apiGroups.count) groups")
                
                DispatchQueue.main.async {
                                            self.groups = apiGroups.map { apiGroup in
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
                                        areaCode: apiPerson.areaCode ?? ""
                                    )
                                },
                                emoji: apiGroup.emoji.isEmpty ? "🏠" : apiGroup.emoji
                            )
                        }
                    self.isLoading = false
                    print("🎉 Groups updated in UI: \(self.groups.count) groups")
                }
            } else {
                // Print response body for error cases
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ Error response body: \(responseString)")
                }
                
                DispatchQueue.main.async {
                    self.errorMessage = "Server error: \(httpResponse.statusCode)"
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
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
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
