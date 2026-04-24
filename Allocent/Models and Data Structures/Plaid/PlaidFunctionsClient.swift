import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFunctions

enum PlaidFunctionsClientError: LocalizedError {
    case invalidResponse
    case missingField(String)
    case notSignedIntoFirebase
    case concurrentRequest

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Unexpected response from the server."
        case .missingField(let name):
            return "Missing field in server response: \(name)"
        case .notSignedIntoFirebase:
            return "You are not signed in to Firebase. Try signing out and back in."
        case .concurrentRequest:
            return "Another bank request is still in progress. Wait a moment and try again."
        }
    }
}

/// Calls Firebase HTTPS callable functions for Plaid (region must match backend).
enum PlaidFunctionsClient {
    private static let functions = Functions.functions(region: "us-central1")

    /// Serialize Plaid calls so we never hit the same HTTPS endpoint concurrently (avoids GTMSessionFetcher "already running").
    private static let callLock = NSLock()
    private static var callInFlight = false

    private static func performCall(_ name: String, _ data: [String: Any], forceRefreshToken: Bool) async throws -> [String: Any] {
        guard let user = Auth.auth().currentUser else {
            throw PlaidFunctionsClientError.notSignedIntoFirebase
        }
        _ = try await user.getIDToken(forcingRefresh: forceRefreshToken)

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String: Any], Error>) in
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

    private static func call(_ name: String, _ data: [String: Any]) async throws -> [String: Any] {
        callLock.lock()
        if callInFlight {
            callLock.unlock()
            throw PlaidFunctionsClientError.concurrentRequest
        }
        callInFlight = true
        callLock.unlock()
        defer {
            callLock.lock()
            callInFlight = false
            callLock.unlock()
        }

        do {
            // Always force-refresh once before Plaid callables.
            // This avoids stale-token edge cases without issuing duplicate requests.
            return try await performCall(name, data, forceRefreshToken: true)
        } catch {
            throw mapFunctionsErrorIfNeeded(error)
        }
    }

    private static func mapFunctionsErrorIfNeeded(_ error: Error) -> Error {
        let ns = error as NSError
        guard ns.domain == FunctionsErrorDomain,
              ns.code == FunctionsErrorCode.unauthenticated.rawValue
        else { return error }

        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
        let firebaseProject = FirebaseApp.app()?.options.projectID ?? "(unknown)"
        let uid = Auth.auth().currentUser?.uid ?? "(nil)"
        let message = """
        Cloud Functions rejected your login (UNAUTHENTICATED). Most often:
        • GoogleService-Info.plist must be from the same Firebase project as your deployed functions (e.g. budgetapp-66eff). This app’s Firebase project id is: \(firebaseProject).
        • After fixing the plist, delete the app from the device and reinstall.
        • Or sign out and sign in again so a fresh ID token is issued.
        (Bundle: \(bundleId), UID: \(uid))
        """
        return NSError(
            domain: ns.domain,
            code: ns.code,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
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
