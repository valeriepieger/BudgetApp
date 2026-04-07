import Foundation
import FirebaseFirestore
import FirebaseAuth

struct ChatSessionService {

    private static func collection() throws -> CollectionReference {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw ChatSessionError.notAuthenticated
        }
        return Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("chat_sessions")
    }

    static func save(_ messages: [ChatMessage]) async throws {
        let userMessages = messages.filter { $0.role == .user }
        guard !userMessages.isEmpty else { return }

        let preview = String(userMessages.first!.content.prefix(80))

        let messagesData: [[String: Any]] = messages.map { msg in
            [
                "id": msg.id.uuidString,
                "role": msg.role.rawValue,
                "content": msg.content,
                "timestamp": Timestamp(date: msg.timestamp)
            ]
        }

        let data: [String: Any] = [
            "createdAt": Timestamp(date: messages.first?.timestamp ?? Date()),
            "preview": preview,
            "messageCount": messages.count,
            "messages": messagesData
        ]

        try await collection().addDocument(data: data)
    }

    static func fetchSessionList() async throws -> [ChatSession] {
        let snapshot = try await collection()
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> ChatSession? in
            let data = doc.data()
            guard let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
                return nil
            }
            return ChatSession(
                id: doc.documentID,
                createdAt: createdAt,
                preview: data["preview"] as? String ?? "",
                messageCount: data["messageCount"] as? Int ?? 0,
                messages: []
            )
        }
    }

    static func fetchSession(id: String) async throws -> ChatSession? {
        let doc = try await collection().document(id).getDocument()
        guard let data = doc.data(),
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
              let messagesData = data["messages"] as? [[String: Any]]
        else { return nil }

        let messages: [ChatMessage] = messagesData.compactMap { msgData in
            guard let idStr = msgData["id"] as? String,
                  let uuid = UUID(uuidString: idStr),
                  let roleStr = msgData["role"] as? String,
                  let role = MessageRole(rawValue: roleStr),
                  let content = msgData["content"] as? String,
                  let timestamp = (msgData["timestamp"] as? Timestamp)?.dateValue()
            else { return nil }
            return ChatMessage(id: uuid, role: role, content: content, timestamp: timestamp)
        }

        return ChatSession(
            id: doc.documentID,
            createdAt: createdAt,
            preview: data["preview"] as? String ?? "",
            messageCount: data["messageCount"] as? Int ?? 0,
            messages: messages
        )
    }
}

enum ChatSessionError: LocalizedError {
    case notAuthenticated
    var errorDescription: String? { "You must be signed in to access chat history." }
}
