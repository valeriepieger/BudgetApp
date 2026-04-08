import Foundation

struct BudgetCategory: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var limit: Double
    var colorHex: String?
    /// When set, the category budget is `monthlyIncome * (limitPercent / 100)` and scales with income.
    var limitPercent: Double?
    
    /// Dollar budget cap for this category using current monthly income.
    func effectiveLimit(monthlyIncome: Double) -> Double {
        if let p = limitPercent, p >= 0, monthlyIncome > 0 {
            return monthlyIncome * (p / 100)
        }
        return limit
    }
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
    var colorHex: String?
    
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

