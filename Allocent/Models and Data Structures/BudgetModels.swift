import Foundation

struct BudgetCategory: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var limit: Double
    var colorHex: String?
}

struct Expense: Identifiable, Codable, Hashable {
    var id: String
    var categoryId: String
    var amount: Double
    var date: Date
    var note: String?
    var month: String
}

struct CategorySummary: Identifiable, Hashable {
    var id: String
    var name: String
    var limit: Double
    var spent: Double
    
    var left: Double {
        max(limit - spent, 0)
    }
}

struct IncomeSource: Identifiable, Codable {
    var id: String
    var name: String
    var amount: Double
    var dateAdded: Date?
}

