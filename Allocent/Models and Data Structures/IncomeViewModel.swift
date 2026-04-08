import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

final class IncomeViewModel: ObservableObject {
    @Published var incomeSources: [IncomeSource] = []
    @Published var totalMonthlyIncome: Double = 0
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private var uid: String? {
        Auth.auth().currentUser?.uid
    }
    
    deinit {
        listener?.remove()
    }
    
    func startListening() {
        guard let uid = uid else { return }
        
        listener = db.collection("users")
            .document(uid)
            .collection("income_sources")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = error.localizedDescription
                    }
                    return
                }
                guard let documents = snapshot?.documents else {
                    DispatchQueue.main.async { self?.errorMessage = nil }
                    return
                }
                
                let sources: [IncomeSource] = documents.map { doc in
                    let data = doc.data()
                    let name = data["name"] as? String ?? ""
                    let amount = Self.double(fromFirestore: data["amount"])
                    var dateAdded: Date?
                    if let ts = data["dateAdded"] as? Timestamp {
                        dateAdded = ts.dateValue()
                    }
                    return IncomeSource(
                        id: doc.documentID,
                        name: name,
                        amount: amount,
                        dateAdded: dateAdded
                    )
                }
                
                let total = sources.reduce(0) { $0 + $1.amount }
                
                DispatchQueue.main.async {
                    self?.errorMessage = nil
                    self?.incomeSources = sources.sorted { ($0.dateAdded ?? .distantPast) >= ($1.dateAdded ?? .distantPast) }
                    self?.totalMonthlyIncome = total
                }
            }
    }
    
    /// Writes to `users/{uid}/income_sources`. Returns whether the write succeeded (listener will refresh the list).
    @discardableResult
    func addSource(name: String, amount: Double) async -> Bool {
        guard let uid = uid else {
            await MainActor.run {
                errorMessage = "You must be signed in to add income."
            }
            return false
        }
        
        let data: [String: Any] = [
            "name": name,
            "amount": amount,
            "dateAdded": FieldValue.serverTimestamp()
        ]
        
        do {
            try await db.collection("users")
                .document(uid)
                .collection("income_sources")
                .addDocument(data: data)
            return true
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    /// Firestore often returns numeric fields as `NSNumber` or `Int`; plain `as? Double` can fail.
    private static func double(fromFirestore value: Any?) -> Double {
        if let d = value as? Double { return d }
        if let n = value as? NSNumber { return n.doubleValue }
        if let i = value as? Int { return Double(i) }
        if let i = value as? Int64 { return Double(i) }
        return 0
    }
    
    func deleteSource(id: String) async {
        guard let uid = uid else { return }
        
        do {
            try await db.collection("users")
                .document(uid)
                .collection("income_sources")
                .document(id)
                .delete()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}
