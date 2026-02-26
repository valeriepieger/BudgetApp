import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

final class DashboardViewModel: ObservableObject {
    @Published var categorySummaries: [CategorySummary] = []
    @Published var totalBudget: Double = 0
    @Published var totalSpent: Double = 0
    @Published var safeToSpend: Double = 0
    
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
    private var uid: String? {
        Auth.auth().currentUser?.uid
    }
    
    private var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
    
    private var lastCategoriesSnapshot: QuerySnapshot?
    private var lastExpensesSnapshot: QuerySnapshot?
    
    deinit {
        listeners.forEach { $0.remove() }
    }
    
    func startListening() {
        guard let uid = uid else { return }
        
        let categoriesRef = db.collection("users")
            .document(uid)
            .collection("categories")
        
        let expensesRef = db.collection("users")
            .document(uid)
            .collection("expenses")
            .whereField("month", isEqualTo: currentMonth)
        
        let catListener = categoriesRef.addSnapshotListener { [weak self] snapshot, _ in
            self?.recompute(categoriesSnapshot: snapshot, expensesSnapshot: nil)
        }
        
        let expListener = expensesRef.addSnapshotListener { [weak self] snapshot, _ in
            self?.recompute(categoriesSnapshot: nil, expensesSnapshot: snapshot)
        }
        
        listeners = [catListener, expListener]
    }
    
    private func recompute(categoriesSnapshot: QuerySnapshot?, expensesSnapshot: QuerySnapshot?) {
        if let categoriesSnapshot = categoriesSnapshot {
            lastCategoriesSnapshot = categoriesSnapshot
        }
        if let expensesSnapshot = expensesSnapshot {
            lastExpensesSnapshot = expensesSnapshot
        }
        
        guard let catSnap = lastCategoriesSnapshot else { return }
        
        var categories: [String: BudgetCategory] = [:]
        for doc in catSnap.documents {
            let data = doc.data()
            let category = BudgetCategory(
                id: doc.documentID,
                name: data["name"] as? String ?? "",
                limit: data["limit"] as? Double ?? 0,
                colorHex: data["colorHex"] as? String
            )
            categories[category.id] = category
        }
        
        var spentByCategory: [String: Double] = [:]
        if let expSnap = lastExpensesSnapshot {
            for doc in expSnap.documents {
                let data = doc.data()
                let categoryId = data["categoryId"] as? String ?? ""
                let amount = data["amount"] as? Double ?? 0
                spentByCategory[categoryId, default: 0] += amount
            }
        }
        
        var summaries: [CategorySummary] = []
        var totalBudget = 0.0
        var totalSpent = 0.0
        
        for category in categories.values {
            let spent = spentByCategory[category.id, default: 0]
            summaries.append(
                CategorySummary(
                    id: category.id,
                    name: category.name,
                    limit: category.limit,
                    spent: spent
                )
            )
            totalBudget += category.limit
            totalSpent += spent
        }
        
        DispatchQueue.main.async {
            self.categorySummaries = summaries.sorted { $0.name < $1.name }
            self.totalBudget = totalBudget
            self.totalSpent = totalSpent
            self.safeToSpend = max(totalBudget - totalSpent, 0)
        }
    }
}

