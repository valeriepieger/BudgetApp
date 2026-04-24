import Foundation

/// Plaid API environment passed to Cloud Functions (`plaidCreateLinkToken`, etc.).
enum PlaidBackendEnvironment: String {
    case sandbox
    case production

    /// Debug builds use Sandbox; Release uses Production. Override with UserDefaults for TestFlight testing.
    static var current: PlaidBackendEnvironment {
        if let raw = UserDefaults.standard.string(forKey: "plaid_environment_override"),
           let env = PlaidBackendEnvironment(rawValue: raw) {
            return env
        }
        #if DEBUG
        return .sandbox
        #else
        return .production
        #endif
    }
}
