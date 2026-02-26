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
                self?.errorMessage = nil
                guard let documents = snapshot?.documents else { return }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                
                let sources: [IncomeSource] = documents.compactMap { doc in
                    let data = doc.data()
                    let name = data["name"] as? String ?? ""
                    let amount = data["amount"] as? Double ?? 0
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
                    self?.incomeSources = sources.sorted { ($0.dateAdded ?? .distantPast) >= ($1.dateAdded ?? .distantPast) }
                    self?.totalMonthlyIncome = total
                }
            }
    }
    
    func addSource(name: String, amount: Double) async {
        guard let uid = uid else { return }
        
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
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
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
