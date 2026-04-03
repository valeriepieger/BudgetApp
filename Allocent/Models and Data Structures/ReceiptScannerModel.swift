//
//  ReceiptScannerModel.swift
//  Allocent
//
//  Created by Amber Liu on 4/2/26.
//

import Foundation
import FoundationModels

// The structured output type that FoundationModels will parse receipt text into.
// The @Generable macro auto-generates the JSON schema and Swift initializer.
@Generable
struct ParsedReceipt {
    @Guide(description: "The name of the merchant or store, cleaned up (e.g. 'Starbucks', not 'STARBUCKS #1234 LLC')")
    var merchant: String

    @Guide(description: "The final total amount paid as a decimal number. Use the TOTAL line, not subtotal or individual items.")
    var amount: Double

    @Guide(description: "The date of the transaction in ISO 8601 format (YYYY-MM-DD). If not found, use today's date.")
    var date: String

    @Guide(description: "Best matching category from: food, transport, groceries, shopping, entertainment, health, utilities, other")
    var category: String
}

extension ParsedReceipt {
    // Maps the raw category string from the model to our TransactionCategory enum
    var transactionCategory: TransactionCategory {
        switch category.lowercased() {
        case "food": return .food
        case "transport": return .transport
        case "groceries": return .groceries
        case "shopping": return .shopping
        case "entertainment": return .entertainment
        case "health": return .health
        case "utilities": return .utilities
        default: return .other
        }
    }

    // Converts the parsed ISO date string to a Swift Date
    var transactionDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: date) ?? .now
    }

    // Converts to a Transaction ready to insert into SwiftData
    func toTransaction() -> Transaction {
        Transaction(
            merchant: merchant,
            amount: amount,
            date: transactionDate,
            category: transactionCategory
        )
    }
}
