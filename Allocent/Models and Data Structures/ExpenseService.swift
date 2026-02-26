import Foundation
import FirebaseFirestore
import FirebaseAuth

struct ExpenseService {
    static func addExpense(
        amount: Double,
        categoryId: String,
        date: Date,
        note: String?
    ) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let month = formatter.string(from: date)
        
        var data: [String: Any] = [
            "amount": amount,
            "categoryId": categoryId,
            "date": Timestamp(date: date),
            "month": month,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        if let note = note {
            data["note"] = note
        }
        
        try await db.collection("users")
            .document(uid)
            .collection("expenses")
            .addDocument(data: data)
    }
}

