import SwiftUI
import CoreLocation

struct RegionDetailView: View {
    let region: CLCircularRegion
    let groups: [UserGroup]
    
    // Computed property to get people in this region grouped by their groups
    private var groupsWithPeopleInRegion: [UserGroup] {
        groups.compactMap { group in
            let peopleInRegion = group.people.filter { $0.areaCode == region.identifier }
            return peopleInRegion.isEmpty ? nil : UserGroup(
                id: group.id,
                name: group.name,
                people: peopleInRegion,
                emoji: group.emoji
            )
        }
    }
    
    private var totalPeopleInRegion: Int {
        groupsWithPeopleInRegion.reduce(0) { $0 + $1.people.count }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with gradient
                    VStack(spacing: 16) {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accent)
                        
                        Text(region.identifier)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("\(totalPeopleInRegion) people here")
                            .font(.headline)
                            .foregroundColor(.accent)
                    }
                    .padding(.top, 20)
                    
                    // Location Details Card
                    ModernCardView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.accent)
                                Text("Location Details")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                DetailRow(title: "Latitude", value: String(format: "%.6f", region.center.latitude))
                                DetailRow(title: "Longitude", value: String(format: "%.6f", region.center.longitude))
                                DetailRow(title: "Radius", value: "\(Int(region.radius)) meters")
                            }
                        }
                        .padding(20)
                    }
                    .padding(.horizontal)
                    
                    // People by Groups Section
                    if !groupsWithPeopleInRegion.isEmpty {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.accent)
                                Text("People Here")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            ForEach(groupsWithPeopleInRegion) { group in
                                GroupPeopleCard(group: group)
                                    .padding(.horizontal)
                            }
                        }
                    } else {
                        ModernCardView {
                            VStack(spacing: 12) {
                                Image(systemName: "person.slash")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                
                                Text("No one here yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Be the first to arrive at \(region.identifier)!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(30)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("Region Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct GroupPeopleCard: View {
    let group: UserGroup
    
    var body: some View {
        ModernCardView {
            VStack(alignment: .leading, spacing: 16) {
                // Group Header
                HStack {
                    Text(group.emoji)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("^[\(group.people.count) person](inflect: true)")
                            .font(.caption)
                            .foregroundColor(.accent)
                    }
                    
                    Spacer()
                }
                
                // People Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(group.people) { person in
                        PersonChip(person: person)
                    }
                }
            }
            .padding(20)
        }
    }
}

struct PersonChip: View {
    let person: Person
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.fill")
                .font(.caption)
                .foregroundColor(.accent)
            
            Text(person.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.accent.opacity(0.1))
                .stroke(Color.accent.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Supporting Views

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Previews

#Preview("RegionDetailView - With People") {
    let sampleRegion = CLCircularRegion(
        center: CLLocationCoordinate2D(latitude: 40.5014, longitude: -74.4474),
        radius: 150.0,
        identifier: "CASC"
    )
    
    let sampleGroups = [
        UserGroup(id: "1", name: "Abusement Park", people: [
            Person(id: "1", name: "Dev", areaCode: "CASC"),
            Person(id: "4", name: "Alex", areaCode: "CASC")
        ], emoji: "🎢"),
        UserGroup(id: "2", name: "Band", people: [
            Person(id: "4", name: "Ezra", areaCode: "CASC"),
            Person(id: "5", name: "Alicia", areaCode: "CASC")
        ], emoji: "🎵"),
        UserGroup(id: "3", name: "RuHere Dev", people: [
            Person(id: "8", name: "Matt", areaCode: "CASC")
        ], emoji: "💻")
    ]
    
    return RegionDetailView(region: sampleRegion, groups: sampleGroups)
}

#Preview("RegionDetailView - Empty") {
    let sampleRegion = CLCircularRegion(
        center: CLLocationCoordinate2D(latitude: 40.5014, longitude: -74.4474),
        radius: 150.0,
        identifier: "LSC"
    )
    
    let sampleGroups = [
        UserGroup(id: "1", name: "Abusement Park", people: [
            Person(id: "1", name: "Dev", areaCode: "CASC"),
            Person(id: "4", name: "Alex", areaCode: "CASC")
        ], emoji: "🎢")
    ]
    
    return RegionDetailView(region: sampleRegion, groups: sampleGroups)
} 
