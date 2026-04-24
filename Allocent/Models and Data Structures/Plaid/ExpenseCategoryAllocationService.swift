import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Maps expense `category` labels to Firestore `categories` document IDs (by `name`), for dashboard rollups.
enum ExpenseCategoryAllocationService {
    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM"
        return f
    }()

    static func currentMonthKey(from date: Date = .now) -> String {
        monthFormatter.string(from: date)
    }

    /// For expenses in `month` with empty `categoryId`, sets `categoryId` when `category` matches a category `name` (case-insensitive).
    static func allocateCategoryIdsForMonth(_ monthKey: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)

        let categoriesSnap = try await userRef.collection("categories").getDocuments()
        var nameLowerToId: [String: String] = [:]
        for doc in categoriesSnap.documents {
            let name = (doc.data()["name"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            nameLowerToId[name.lowercased()] = doc.documentID
        }
        guard !nameLowerToId.isEmpty else { return }

        let expensesSnap = try await userRef.collection("expenses")
            .whereField("month", isEqualTo: monthKey)
            .getDocuments()

        let chunk = 400
        var batch = db.batch()
        var ops = 0

        for doc in expensesSnap.documents {
            let d = doc.data()
            let existingId = (d["categoryId"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !existingId.isEmpty { continue }

            let label = (d["category"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !label.isEmpty else { continue }
            guard let categoryId = nameLowerToId[label.lowercased()] else { continue }

            batch.updateData(["categoryId": categoryId], forDocument: doc.reference)
            ops += 1
            if ops >= chunk {
                try await batch.commit()
                batch = db.batch()
                ops = 0
            }
        }
        if ops > 0 {
            try await batch.commit()
        }
    }
}
