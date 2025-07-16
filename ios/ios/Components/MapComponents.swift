import CoreLocation
import SwiftUI

struct ModernPersonAnnotation: View {
    let annotation: PersonAnnotation

    var body: some View {
        VStack(spacing: 8) {
            ForEach(annotation.allPeople) { person in
                Text(person.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview("Single Person") {
    let samplePerson = Person(id: "1", name: "John Doe", areaCode: "CASC")
    let sampleGroup = UserGroup(
        id: "1", name: "Study Group", people: [samplePerson], emoji: "📚")
    let sampleAnnotation = PersonAnnotation(
        person: samplePerson,
        coordinate: CLLocationCoordinate2D(
            latitude: 40.5014, longitude: -74.4474),
        allPeople: [samplePerson],
        group: sampleGroup
    )

    return ModernPersonAnnotation(annotation: sampleAnnotation)
        .padding()
        .background(Color.gray.opacity(0.1))
}

#Preview("Multiple People") {
    let person1 = Person(id: "1", name: "Alice", areaCode: "CASC")
    let person2 = Person(id: "2", name: "Bob", areaCode: "CASC")
    let person3 = Person(id: "3", name: "Charlie", areaCode: "CASC")
    let sampleGroup = UserGroup(
        id: "1", name: "Dev Team", people: [person1, person2, person3],
        emoji: "💻")
    let sampleAnnotation = PersonAnnotation(
        person: person1,
        coordinate: CLLocationCoordinate2D(
            latitude: 40.5014, longitude: -74.4474),
        allPeople: [person1, person2, person3],
        group: sampleGroup
    )

    return ModernPersonAnnotation(annotation: sampleAnnotation)
        .padding()
        .background(Color.gray.opacity(0.1))
}
