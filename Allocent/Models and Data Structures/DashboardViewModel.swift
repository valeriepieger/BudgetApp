import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

final class DashboardViewModel: ObservableObject {
    @Published var categorySummaries: [CategorySummary] = []
    /// Sum of category limits (allocated budget).
    @Published var totalBudget: Double = 0
    @Published var totalMonthlyIncome: Double = 0
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
    private var lastIncomeSnapshot: QuerySnapshot?
    
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
        
        let incomeRef = db.collection("users")
            .document(uid)
            .collection("income_sources")
        
        let catListener = categoriesRef.addSnapshotListener { [weak self] snapshot, _ in
            self?.recompute(categoriesSnapshot: snapshot, expensesSnapshot: nil, incomeSnapshot: nil)
        }
        
        let expListener = expensesRef.addSnapshotListener { [weak self] snapshot, _ in
            self?.recompute(categoriesSnapshot: nil, expensesSnapshot: snapshot, incomeSnapshot: nil)
        }
        
        let incomeListener = incomeRef.addSnapshotListener { [weak self] snapshot, _ in
            self?.recompute(categoriesSnapshot: nil, expensesSnapshot: nil, incomeSnapshot: snapshot)
        }
        
        listeners = [catListener, expListener, incomeListener]
    }
    
    private func recompute(categoriesSnapshot: QuerySnapshot?, expensesSnapshot: QuerySnapshot?, incomeSnapshot: QuerySnapshot?) {
        if let categoriesSnapshot = categoriesSnapshot {
            lastCategoriesSnapshot = categoriesSnapshot
        }
        if let expensesSnapshot = expensesSnapshot {
            lastExpensesSnapshot = expensesSnapshot
        }
        if let incomeSnapshot = incomeSnapshot {
            lastIncomeSnapshot = incomeSnapshot
        }
        
        var totalMonthlyIncome = 0.0
        if let incSnap = lastIncomeSnapshot {
            for doc in incSnap.documents {
                totalMonthlyIncome += Self.double(fromFirestore: doc.data()["amount"])
            }
        }
        
        guard let catSnap = lastCategoriesSnapshot else {
            DispatchQueue.main.async {
                self.totalMonthlyIncome = totalMonthlyIncome
            }
            return
        }
        
        var categories: [String: BudgetCategory] = [:]
        for doc in catSnap.documents {
            let data = doc.data()
            let category = BudgetCategory(
                id: doc.documentID,
                name: data["name"] as? String ?? "",
                limit: Self.double(fromFirestore: data["limit"]),
                colorHex: data["colorHex"] as? String
            )
            categories[category.id] = category
        }
        
        var spentByCategory: [String: Double] = [:]
        if let expSnap = lastExpensesSnapshot {
            for doc in expSnap.documents {
                let data = doc.data()
                let categoryId = data["categoryId"] as? String ?? ""
                let amount = Self.double(fromFirestore: data["amount"])
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
                    spent: spent,
                    colorHex: category.colorHex
                )
            )
            totalBudget += category.limit
            totalSpent += spent
        }
        
        DispatchQueue.main.async {
            self.categorySummaries = summaries.sorted { $0.name < $1.name }
            self.totalBudget = totalBudget
            self.totalMonthlyIncome = totalMonthlyIncome
            self.totalSpent = totalSpent
            self.safeToSpend = max(totalBudget - totalSpent, 0)
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

