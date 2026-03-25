//
//  AuthService.swift
//  Allocent
//
//  Created by Amber Liu on 2/26/26.
//

import Foundation
import FirebaseAuth

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

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}
