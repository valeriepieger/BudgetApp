import Foundation
import FirebaseFunctions

enum PlaidFunctionsClientError: LocalizedError {
    case invalidResponse
    case missingField(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Unexpected response from the server."
        case .missingField(let name):
            return "Missing field in server response: \(name)"
        }
    }
}

/// Calls Firebase HTTPS callable functions for Plaid (region must match backend).
enum PlaidFunctionsClient {
    private static let functions = Functions.functions(region: "us-central1")

    private static func call(_ name: String, _ data: [String: Any]) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            functions.httpsCallable(name).call(data) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let dict = result?.data as? [String: Any] else {
                    continuation.resume(throwing: PlaidFunctionsClientError.invalidResponse)
                    return
                }
                continuation.resume(returning: dict)
            }
        }
    }

    static func createLinkToken(environment: PlaidBackendEnvironment = .current) async throws -> String {
        let data = try await call("plaidCreateLinkToken", ["environment": environment.rawValue])
        guard let token = data["linkToken"] as? String, !token.isEmpty else {
            throw PlaidFunctionsClientError.missingField("linkToken")
        }
        return token
    }

    static func exchangePublicToken(_ publicToken: String, environment: PlaidBackendEnvironment = .current) async throws -> (itemId: String, institutionName: String?) {
        let data = try await call("plaidExchangePublicToken", [
            "publicToken": publicToken,
            "environment": environment.rawValue,
        ])
        guard let itemId = data["itemId"] as? String, !itemId.isEmpty else {
            throw PlaidFunctionsClientError.missingField("itemId")
        }
        let institution = data["institutionName"] as? String
        return (itemId, institution)
    }

    /// Pulls transactions from Plaid and writes `users/{uid}/expenses` documents.
    static func syncTransactions(itemId: String? = nil) async throws -> [String: Any] {
        var payload: [String: Any] = [:]
        if let itemId, !itemId.isEmpty {
            payload["itemId"] = itemId
        }
        return try await call("plaidSyncTransactions", payload)
    }
}
