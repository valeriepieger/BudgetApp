//import Foundation
//import SwiftUI
//import FirebaseFirestore
//import FirebaseAuth
//import Combine
//
//final class DashboardViewModel: ObservableObject {
//    @Published var categorySummaries: [CategorySummary] = []
//    @Published var totalBudget: Double = 0
//    @Published var totalSpent: Double = 0
//    @Published var safeToSpend: Double = 0
//    
//    private let db = Firestore.firestore()
//    private var listeners: [ListenerRegistration] = []
//    
//    private var uid: String? {
//        Auth.auth().currentUser?.uid
//    }
//    
//    private var currentMonth: String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM"
//        return formatter.string(from: Date())
//    }
//    
//    private var lastCategoriesSnapshot: QuerySnapshot?
//    private var lastExpensesSnapshot: QuerySnapshot?
//    
//    deinit {
//        listeners.forEach { $0.remove() }
//    }
//    
//    func startListening() {
//        guard let uid = uid else { return }
//        
//        let categoriesRef = db.collection("users")
//            .document(uid)
//            .collection("categories")
//        
//        let expensesRef = db.collection("users")
//            .document(uid)
//            .collection("expenses")
//            .whereField("month", isEqualTo: currentMonth)
//        
//        let catListener = categoriesRef.addSnapshotListener { [weak self] snapshot, _ in
//            self?.recompute(categoriesSnapshot: snapshot, expensesSnapshot: nil)
//        }
//        
//        let expListener = expensesRef.addSnapshotListener { [weak self] snapshot, _ in
//            self?.recompute(categoriesSnapshot: nil, expensesSnapshot: snapshot)
//        }
//        
//        listeners = [catListener, expListener]
//    }
//    
//    private func recompute(categoriesSnapshot: QuerySnapshot?, expensesSnapshot: QuerySnapshot?) {
//        if let categoriesSnapshot = categoriesSnapshot {
//            lastCategoriesSnapshot = categoriesSnapshot
//        }
//        if let expensesSnapshot = expensesSnapshot {
//            lastExpensesSnapshot = expensesSnapshot
//        }
//        
//        guard let catSnap = lastCategoriesSnapshot else { return }
//        
//        var categories: [String: BudgetCategory] = [:]
//        for doc in catSnap.documents {
//            let data = doc.data()
//            let category = BudgetCategory(
//                id: doc.documentID,
//                name: data["name"] as? String ?? "",
//                limit: data["limit"] as? Double ?? 0,
//                colorHex: data["colorHex"] as? String
//            )
//            categories[category.id] = category
//        }
//        
//        var spentByCategory: [String: Double] = [:]
//        if let expSnap = lastExpensesSnapshot {
//            for doc in expSnap.documents {
//                let data = doc.data()
//                let categoryId = data["categoryId"] as? String ?? ""
//                let amount = data["amount"] as? Double ?? 0
//                spentByCategory[categoryId, default: 0] += amount
//            }
//        }
//        
//        var summaries: [CategorySummary] = []
//        var totalBudget = 0.0
//        var totalSpent = 0.0
//        
//        for category in categories.values {
//            let spent = spentByCategory[category.id, default: 0]
//            summaries.append(
//                CategorySummary(
//                    id: category.id,
//                    name: category.name,
//                    limit: category.limit,
//                    spent: spent
//                )
//            )
//            totalBudget += category.limit
//            totalSpent += spent
//        }
//        
//        DispatchQueue.main.async {
//            self.categorySummaries = summaries.sorted { $0.name < $1.name }
//            self.totalBudget = totalBudget
//            self.totalSpent = totalSpent
//            self.safeToSpend = max(totalBudget - totalSpent, 0)
//        }
//    }
//}
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

final class DashboardViewModel: ObservableObject {
    @Published var categorySummaries: [CategorySummary] = []
    @Published var totalBudget: Double = 0
    @Published var totalMonthlyIncome: Double = 0
    @Published var totalSpent: Double = 0
    @Published var safeToSpend: Double = 0

    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private var visibleCategories: Set<String> = []

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

        db.collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            guard let self = self else { return }

            if let data = snapshot?.data(),
               let visible = data["visibleCategories"] as? [String] {
                self.visibleCategories = Set(visible)
            }

            self.attachListeners(uid: uid)
        }
    }

    private func attachListeners(uid: String) {
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
                totalMonthlyIncome += doubleFromFirestore(doc.data()["amount"])
            }
        }

        guard let catSnap = lastCategoriesSnapshot else {
            DispatchQueue.main.async {
                self.totalMonthlyIncome = totalMonthlyIncome
                self.safeToSpend = max(totalMonthlyIncome, 0)
            }
            return
        }

        var categories: [String: BudgetCategory] = [:]
        for doc in catSnap.documents {
            let data = doc.data()
            let category = BudgetCategory(
                id: doc.documentID,
                name: data["name"] as? String ?? "",
                limit: doubleFromFirestore(data["limit"]),
                colorHex: data["colorHex"] as? String
            )
            categories[category.id] = category
        }

        var spentByCategory: [String: Double] = [:]
        if let expSnap = lastExpensesSnapshot {
            for doc in expSnap.documents {
                let data = doc.data()
                let categoryId = data["categoryId"] as? String ?? ""
                let amount = doubleFromFirestore(data["amount"])
                spentByCategory[categoryId, default: 0] += amount
            }
        }

        var summaries: [CategorySummary] = []
        var totalBudget = 0.0
        var totalSpent = 0.0

        for category in categories.values {
            guard visibleCategories.isEmpty || visibleCategories.contains(category.name) else { continue }

            let spent = spentByCategory[category.id, default: 0]
            let cap = category.limit
            summaries.append(
                CategorySummary(
                    id: category.id,
                    name: category.name,
                    limit: cap,
                    spent: spent
                )
            )
            totalBudget += cap
            totalSpent += spent
        }

        let safeToSpend: Double
        if totalBudget > 0 {
            safeToSpend = max(totalBudget - totalSpent, 0)
        } else {
            safeToSpend = max(totalMonthlyIncome, 0)
        }

        DispatchQueue.main.async {
            self.categorySummaries = summaries.sorted { $0.name < $1.name }
            self.totalBudget = totalBudget
            self.totalMonthlyIncome = totalMonthlyIncome
            self.totalSpent = totalSpent
            self.safeToSpend = safeToSpend
        }
    }

    private func doubleFromFirestore(_ value: Any?) -> Double {
        if let d = value as? Double { return d }
        if let n = value as? NSNumber { return n.doubleValue }
        if let i = value as? Int { return Double(i) }
        if let i = value as? Int64 { return Double(i) }
        return 0
    }

    private func optionalDoubleFromFirestore(_ value: Any?) -> Double? {
        guard let value, !(value is NSNull) else { return nil }
        return doubleFromFirestore(value)
    }
}
