//
//  TransactionCategory.swift
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

    var emoji: String {
        switch self {
        case .food: return "🍔"
        case .transport: return "🚗"
        case .groceries: return "🛒"
        case .shopping: return "🛍️"
        case .entertainment: return "🎬"
        case .health: return "💊"
        case .utilities: return "💡"
        case .other: return "📦"
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
}

struct Transaction: Identifiable {
    var id: String
    var merchant: String
    var amount: Double
    var date: Date
    var category: TransactionCategory
    var notes: String

    init(
        id: String = UUID().uuidString,
        merchant: String,
        amount: Double,
        date: Date = .now,
        category: TransactionCategory = .other,
        notes: String = ""
    ) {
        self.id = id
        self.merchant = merchant
        self.amount = amount
        self.date = date
        self.category = category
        self.notes = notes
    }

    var firestoreData: [String: Any] {
        [
            "merchant": merchant,
            "amount": amount,
            "date": Timestamp(date: date),
            "category": category.rawValue,
            "notes": notes
        ]
    }

    static func from(_ doc: DocumentSnapshot) -> Transaction? {
        guard let data = doc.data() else { return nil }
        return Transaction(
            id: doc.documentID,
            merchant: data["merchant"] as? String ?? "",
            amount: data["amount"] as? Double ?? 0,
            date: (data["date"] as? Timestamp)?.dateValue() ?? .now,
            category: TransactionCategory(rawValue: data["category"] as? String ?? "") ?? .other,
            notes: data["notes"] as? String ?? ""
        )
    }
}
