import Foundation

struct Note: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String = ""
    var body: String = ""
    var createdAt: Date = .now
}
