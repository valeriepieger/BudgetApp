//
//  TransactionModel.swift
//  Allocent
//
//  Created by Amber Liu on 4/2/26.
//

import Foundation
import FirebaseFirestore

enum TransactionCategory: String, Codable, CaseIterable {
    case food = "Food & Drink"
    case transport = "Transport"
    case groceries = "Groceries"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case health = "Health"
    case utilities = "Utilities"
    case other = "Other"

    var iconName: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .groceries: return "cart.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "film.fill"
        case .health: return "heart.fill"
        case .utilities: return "bolt.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .food: return "orange"
        case .transport: return "blue"
        case .groceries: return "green"
        case .shopping: return "pink"
        case .entertainment: return "purple"
        case .health: return "red"
        case .utilities: return "yellow"
        case .other: return "gray"
        }
    }

    /// Attempts to find the best matching BudgetCategory by name
    func bestMatch(in budgetCategories: [BudgetCategory]) -> BudgetCategory? {
        let selfName = rawValue.lowercased()
        // First try exact or contains match
        if let exact = budgetCategories.first(where: {
            $0.name.lowercased() == selfName ||
            $0.name.lowercased().contains(selfName) ||
            selfName.contains($0.name.lowercased())
        }) {
            return exact
        }
        // Keyword fallback matching
        let keywords: [String] = {
            switch self {
            case .food: return ["food", "dining", "restaurant", "eat", "drink", "coffee", "lunch", "dinner"]
            case .transport: return ["transport", "travel", "car", "gas", "uber", "lyft", "transit", "fuel"]
            case .groceries: return ["grocer", "market", "supermarket", "food", "costco", "walmart", "target"]
            case .shopping: return ["shop", "retail", "clothes", "amazon", "store"]
            case .entertainment: return ["entertainment", "fun", "movie", "music", "game", "sport", "streaming"]
            case .health: return ["health", "medical", "pharmacy", "doctor", "gym", "fitness", "wellness"]
            case .utilities: return ["utilities", "bill", "electric", "water", "internet", "phone", "rent"]
            case .other: return []
            }
        }()
        return budgetCategories.first { cat in
            keywords.contains(where: { cat.name.lowercased().contains($0) })
        }
    }
}

/// A transaction read from the expenses collection.
/// Expenses now store merchant + category fields alongside amount/date/categoryId.
struct Transaction: Identifiable {
    var id: String
    var merchant: String
    var amount: Double
    var date: Date
    var category: TransactionCategory
    var categoryId: String
    var notes: String

    init(
        id: String = UUID().uuidString,
        merchant: String,
        amount: Double,
        date: Date = .now,
        category: TransactionCategory = .other,
        categoryId: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.merchant = merchant
        self.amount = amount
        self.date = date
        self.category = category
        self.categoryId = categoryId
        self.notes = notes
    }

    /// Firestore data for saving a scanned receipt as an expense
    func toExpenseData() -> [String: Any] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let month = formatter.string(from: date)

        var data: [String: Any] = [
            "amount": amount,
            "categoryId": categoryId,
            "date": Timestamp(date: date),
            "month": month,
            "merchant": merchant,
            "category": category.rawValue,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if !notes.isEmpty {
            data["note"] = notes
        }
        return data
    }

    /// Read a Transaction back from an expense document
    static func from(_ doc: DocumentSnapshot) -> Transaction? {
        guard let data = doc.data() else { return nil }
        return Transaction(
            id: doc.documentID,
            merchant: data["merchant"] as? String ?? "",
            amount: data["amount"] as? Double ?? 0,
            date: (data["date"] as? Timestamp)?.dateValue() ?? .now,
            category: TransactionCategory(rawValue: data["category"] as? String ?? "") ?? .other,
            categoryId: data["categoryId"] as? String ?? "",
            notes: data["note"] as? String ?? ""
        )
    }
}
