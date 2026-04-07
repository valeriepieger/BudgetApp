import Foundation

struct ChatSession: Identifiable, Codable {
    let id: String
    let createdAt: Date
    let preview: String
    let messageCount: Int
    let messages: [ChatMessage]

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}
