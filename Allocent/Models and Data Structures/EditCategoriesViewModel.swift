import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

final class EditCategoriesViewModel: ObservableObject {
    @Published var categories: [BudgetCategory] = []
    @Published var totalIncome: Double = 0
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var categoriesListener: ListenerRegistration?
    private var incomeListener: ListenerRegistration?
    
    private var uid: String? {
        Auth.auth().currentUser?.uid
    }
    
    var totalAllocated: Double {
        categories.reduce(0) { $0 + $1.limit }
    }
    
    var leftToBudget: Double {
        max(totalIncome - totalAllocated, 0)
    }
    
    var allocationPercentText: String {
        guard totalIncome > 0 else { return "Set income to see allocation" }
        let pct = (totalAllocated / totalIncome) * 100
        return String(format: "%.0f%% of 100%% allocated", min(pct, 100))
    }
    
    deinit {
        categoriesListener?.remove()
        incomeListener?.remove()
    }
    
    func startListening() {
        guard let uid = uid else { return }
        
        let categoriesRef = db.collection("users")
            .document(uid)
            .collection("categories")
        
        categoriesListener = categoriesRef.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
                return
            }
            self?.errorMessage = nil
            guard let documents = snapshot?.documents else { return }
            
            let list: [BudgetCategory] = documents.map { doc in
                let data = doc.data()
                return BudgetCategory(
                    id: doc.documentID,
                    name: data["name"] as? String ?? "",
                    limit: data["limit"] as? Double ?? 0,
                    colorHex: data["colorHex"] as? String
                )
            }
            
            DispatchQueue.main.async {
                self?.categories = list.sorted { $0.name < $1.name }
            }
        }
        
        let incomeRef = db.collection("users")
            .document(uid)
            .collection("income_sources")
        
        incomeListener = incomeRef.addSnapshotListener { [weak self] snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            let total = documents.reduce(0) { $0 + Self.double(fromFirestore: $1.data()["amount"]) }
            DispatchQueue.main.async {
                self?.totalIncome = total
            }
        }
    }
    
    func addCategory(name: String, limit: Double) async {
        guard let uid = uid else { return }
        
        let data: [String: Any] = [
            "name": name,
            "limit": limit
        ]
        
        do {
            try await db.collection("users")
                .document(uid)
                .collection("categories")
                .addDocument(data: data)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func updateCategory(id: String, name: String, limit: Double) async {
        guard let uid = uid else { return }
        
        let data: [String: Any] = [
            "name": name,
            "limit": limit
        ]
        
        do {
            try await db.collection("users")
                .document(uid)
                .collection("categories")
                .document(id)
                .updateData(data)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteCategory(id: String) async {
        guard let uid = uid else { return }
        
        do {
            try await db.collection("users")
                .document(uid)
                .collection("categories")
                .document(id)
                .delete()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private static func double(fromFirestore value: Any?) -> Double {
        if let d = value as? Double { return d }
        if let n = value as? NSNumber { return n.doubleValue }
        if let i = value as? Int { return Double(i) }
        if let i = value as? Int64 { return Double(i) }
        return 0
    }
}
