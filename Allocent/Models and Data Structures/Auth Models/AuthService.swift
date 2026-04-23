//
//  AuthService.swift
//  Allocent
//
//  Created by Amber Liu on 2/26/26.
//

import Foundation
import FirebaseAuth
import FirebaseCore
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

final class AuthService {

    func currentUID() -> String? {
        Auth.auth().currentUser?.uid
    }

    func currentEmail() -> String? {
        Auth.auth().currentUser?.email
    }

    func createUser(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user.uid
    }

    func signIn(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user.uid
    }

    //Signs in with Google and returns (uid, email, displayName)
    //If the user is new to Firebase Auth, isNewUser will be true
    @MainActor
    func signInWithGoogle() async throws -> (uid: String, email: String, fullName: String, isNewUser: Bool) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "AuthService", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Missing Firebase client ID"])
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            throw NSError(domain: "AuthService", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "No root view controller found"])
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "AuthService", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Missing Google ID token"])
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        let isNewUser = authResult.additionalUserInfo?.isNewUser ?? false
        let email = authResult.user.email ?? ""
        let fullName = authResult.user.displayName ?? ""

        return (authResult.user.uid, email, fullName, isNewUser)
    }

    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}
