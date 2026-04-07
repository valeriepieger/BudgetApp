//
//  ReceiptParser.swift
//  Allocent
//
//  Created by Amber Liu on 4/2/26.
//

import Foundation

struct ReceiptParser {

    static func parse(_ rawText: String) async throws -> Transaction {
        let prompt = """
        Parse this receipt OCR text and return ONLY a JSON object with these fields:
        - merchant: string (brand name only, no store numbers or LLC/Inc)
        - amount: number (the grand total paid. Look for the largest number appearing after a label like TOTAL, AMOUNT DUE, AMOUNT CHARGED, or GRAND TOTAL. Ignore individual item prices, subtotal, and tax.)
        - date: string (YYYY-MM-DD format, use today if not found)
        - category: string (one of: food, transport, groceries, shopping, entertainment, health, utilities, other)

        Receipt text:
        \(rawText)

        Return ONLY the JSON object, no explanation, no markdown, no backticks.
        """

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 256,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let rawResponse = String(data: data, encoding: .utf8) ?? "no response body"
        print("Anthropic status: \(statusCode)")
        print("Anthropic response: \(rawResponse)")

        guard statusCode == 200 else {
            throw ReceiptParserError.apiError
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw ReceiptParserError.invalidResponse
        }

        // Strip markdown backticks if Claude included them
        let cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanedText.data(using: .utf8),
              let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw ReceiptParserError.parseError
        }

        let merchant = parsed["merchant"] as? String ?? "Unknown"
        let amount = parsed["amount"] as? Double ?? 0
        let dateString = parsed["date"] as? String ?? ""
        let categoryString = parsed["category"] as? String ?? "other"

        // Use local timezone to avoid off-by-one date issue
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let date = formatter.date(from: dateString) ?? .now

        let category: TransactionCategory
        switch categoryString.lowercased() {
        case "food": category = .food
        case "transport": category = .transport
        case "groceries": category = .groceries
        case "shopping": category = .shopping
        case "entertainment": category = .entertainment
        case "health": category = .health
        case "utilities": category = .utilities
        default: category = .other
        }

        return Transaction(
            merchant: merchant,
            amount: amount,
            date: date,
            category: category
        )
    }
}

enum ReceiptParserError: LocalizedError {
    case apiError
    case invalidResponse
    case parseError

    var errorDescription: String? {
        switch self {
        case .apiError: return "Failed to connect to the parsing service."
        case .invalidResponse: return "Received an unexpected response."
        case .parseError: return "Could not parse the receipt data."
        }
    }
}
