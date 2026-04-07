//
//  AdvisorViewModel.swift
//  Allocent
//
//  Created by Valerie on 3/29/26.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
@Observable
final class AdvisorViewModel {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false

    //chat history state
    var showHistory: Bool = false
    var pastSessions: [ChatSession] = []
    var isLoadingHistory: Bool = false
    var selectedSession: ChatSession? = nil
    var isLoadingSession: Bool = false

    private var systemPrompt: String = ""
    private let db = Firestore.firestore()

    private var uid: String? {
        Auth.auth().currentUser?.uid
    }

    private var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }

    func setup() async {
        systemPrompt = await buildSystemInstructions()

        messages.append(ChatMessage(
            role: .assistant,
            content: "Hi! I've loaded your budget data for this month. You can ask me things like \"How much do I have left for food?\" or \"Which categories am I spending the most in?\""
        ))
    }

    //send message to the Anthropic API
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage(role: .user, content: text))
        inputText = ""
        isLoading = true

        do {
            let reply = try await callAnthropic(userMessage: text)
            messages.append(ChatMessage(role: .assistant, content: reply))
        } catch {
            messages.append(ChatMessage(
                role: .system,
                content: "Something went wrong. Please try again."
            ))
        }

        isLoading = false
    }

    //new session when navigates back to advisor tab
    func startNewSession() async {
        guard hasUserMessages else { return }
        await saveCurrentSessionIfNeeded()
        messages.removeAll()
        await setup()
    }

    func resetSession() async {
        messages.removeAll()
        await setup()
    }

    //for chat history
    func loadHistory() async {
        isLoadingHistory = true
        do {
            pastSessions = try await ChatSessionService.fetchSessionList()
        } catch {
            pastSessions = []
        }
        isLoadingHistory = false
    }

    func loadSession(id: String) async {
        isLoadingSession = true
        do {
            selectedSession = try await ChatSessionService.fetchSession(id: id)
        } catch {
            selectedSession = nil
        }
        isLoadingSession = false
    }

    private var hasUserMessages: Bool {
        messages.contains { $0.role == .user }
    }

    private func saveCurrentSessionIfNeeded() async {
        guard hasUserMessages else { return }
        do {
            try await ChatSessionService.save(messages)
        } catch {
            print("Failed to save chat session: \(error.localizedDescription)")
        }
    }


    private func callAnthropic(userMessage: String) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Secrets.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        //build conversation history from messages (excluding system messages)
        var apiMessages: [[String: String]] = []
        for msg in messages {
            switch msg.role {
            case .user:
                apiMessages.append(["role": "user", "content": msg.content])
            case .assistant:
                apiMessages.append(["role": "assistant", "content": msg.content])
            case .system:
                break
            }
        }

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": apiMessages
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AnthropicError.requestFailed
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            throw AnthropicError.invalidResponse
        }

        return text
    }


    private func buildSystemInstructions() async -> String {
        var parts: [String] = []

        parts.append("""
            You are a helpful assistant inside a personal budgeting app called Allocent. \
            Your role is to help the user understand and organize their own budget data shown below. \
            You can summarize their spending, compare categories, point out which categories \
            have room left, and suggest everyday ways to stay within their budget. \
            You are NOT a financial advisor. Do not recommend investments, credit products, or \
            financial services. Just help them make sense of their own numbers. \
            Keep responses short (2-4 sentences) unless the user asks for more detail. \
            Be encouraging and practical. \
            IMPORTANT: Do NOT use markdown formatting such as asterisks, hashtags, or backticks. \
            Use plain text only. For lists, use dashes. For emphasis, use CAPS sparingly.
            """)

        guard let uid else {
            parts.append("No user data is available.")
            return parts.joined(separator: "\n\n")
        }

        //fetch budget categories
        var categories: [BudgetCategory] = []
        if let snap = try? await db.collection("users").document(uid)
            .collection("categories").getDocuments() {
            categories = snap.documents.map { doc in
                let data = doc.data()
                return BudgetCategory(
                    id: doc.documentID,
                    name: data["name"] as? String ?? "",
                    limit: data["limit"] as? Double ?? 0,
                    colorHex: data["colorHex"] as? String
                )
            }
        }

        //fetch expenses for current month
        var spentByCategory: [String: Double] = [:]
        if let snap = try? await db.collection("users").document(uid)
            .collection("expenses")
            .whereField("month", isEqualTo: currentMonth)
            .getDocuments() {
            for doc in snap.documents {
                let data = doc.data()
                let catId = data["categoryId"] as? String ?? ""
                let amount = data["amount"] as? Double ?? 0
                spentByCategory[catId, default: 0] += amount
            }
        }

        //fetch income sources
        var incomeSources: [IncomeSource] = []
        if let snap = try? await db.collection("users").document(uid)
            .collection("income_sources").getDocuments() {
            incomeSources = snap.documents.map { doc in
                let data = doc.data()
                return IncomeSource(
                    id: doc.documentID,
                    name: data["name"] as? String ?? "",
                    amount: data["amount"] as? Double ?? 0,
                    dateAdded: nil
                )
            }
        }

        //fetch transactions
        var transactions: [Transaction] = []
        if let fetched = try? await TransactionService.fetch() {
            transactions = fetched
        }

        let totalIncome = incomeSources.reduce(0) { $0 + $1.amount }
        let totalBudget = categories.reduce(0) { $0 + $1.limit }
        let totalSpent = spentByCategory.values.reduce(0, +)
        let safeToSpend = max(totalBudget - totalSpent, 0)

        parts.append("--- USER'S BUDGET DATA (Current Month: \(currentMonth)) ---")

        // Income
        if !incomeSources.isEmpty {
            let lines = incomeSources.map { "  - \($0.name): $\(String(format: "%.2f", $0.amount))" }
            parts.append("Income Sources:\n\(lines.joined(separator: "\n"))\nTotal Monthly Income: $\(String(format: "%.2f", totalIncome))")
        } else {
            parts.append("Income: No income sources set up yet.")
        }

        // Categories & expenses
        if !categories.isEmpty {
            var lines: [String] = []
            for cat in categories.sorted(by: { $0.name < $1.name }) {
                let spent = spentByCategory[cat.id, default: 0]
                let left = max(cat.limit - spent, 0)
                let pct = cat.limit > 0 ? (spent / cat.limit) * 100 : 0
                lines.append("  - \(cat.name): Budget $\(String(format: "%.2f", cat.limit)), Spent $\(String(format: "%.2f", spent)), Remaining $\(String(format: "%.2f", left)) (\(String(format: "%.0f", pct))% used)")
            }
            parts.append("Budget Categories:\n\(lines.joined(separator: "\n"))")
        } else {
            parts.append("Budget Categories: None set up yet.")
        }

        // Transactions
        if !transactions.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            // Show up to 30 most recent transactions to keep the prompt reasonable
            let recent = transactions.prefix(30)
            var lines: [String] = []
            for t in recent {
                let dateStr = dateFormatter.string(from: t.date)
                lines.append("  - \(dateStr) | \(t.merchant) | $\(String(format: "%.2f", t.amount)) | \(t.category.rawValue)\(t.notes.isEmpty ? "" : " | \(t.notes)")")
            }
            let totalTransactions = transactions.count
            var header = "Recent Transactions (\(recent.count) of \(totalTransactions)):"
            if totalTransactions > 30 {
                header += " (showing most recent 30)"
            }
            parts.append("\(header)\n\(lines.joined(separator: "\n"))")
        } else {
            parts.append("Transactions: None recorded yet.")
        }

        // Summary
        parts.append("""
            Summary:
              Total Budget: $\(String(format: "%.2f", totalBudget))
              Total Spent: $\(String(format: "%.2f", totalSpent))
              Safe to Spend: $\(String(format: "%.2f", safeToSpend))
            """)

        return parts.joined(separator: "\n\n")
    }
}

enum AnthropicError: LocalizedError {
    case requestFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .requestFailed: return "The request to the AI service failed."
        case .invalidResponse: return "Received an invalid response from the AI service."
        }
    }
}

