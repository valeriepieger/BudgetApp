//
//  SessionViewModel.swift
//  Allocent
//
//  Created by Amber Liu on 2/26/26.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class SessionViewModel: ObservableObject {

    @Published private(set) var state: SessionState = .loading

    private let auth: AuthService
    private let users: UserService
    
    init(auth: AuthService? = nil, users: UserService? = nil) {
            self.auth = auth ?? AuthService()
            self.users = users ?? UserService()
        }

    // Called when the app launches to determine initial state
    func loadSession() async {
        state = .loading

        guard let uid = auth.currentUID() else {
            state = .signedOut
            return
        }

        do {
            let user = try await users.fetchUser(uid: uid)
            if user.needsOnboarding {
                state = .onboarding(user)
            } else {
                state = .active(user)
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // Handles signing in an existing user
    func signIn(email: String, password: String) async {
        state = .loading
        do {
            let uid = try await auth.signIn(email: email, password: password)
            let user = try await users.fetchUser(uid: uid)

            if user.needsOnboarding {
                state = .onboarding(user)
            } else {
                state = .active(user)
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // Handles creating a new user account
    func signUp(firstName: String,
                lastName: String,
                email: String,
                phoneNumber: String,
                bio: String,
                password: String) async {
        state = .loading

        do {
            // Step 1: Create Firebase Auth user
            let uid = try await auth.createUser(email: email, password: password)

            let newUser = AppUser(
                id: uid,
                firstName: firstName,
                lastName: lastName,
                email: email,
                phoneNumber: phoneNumber,
                bio: bio,
                createdAt: Date(),
                needsOnboarding: true,
                linked: false
            )

            // create Firestore user doc
            do {
                try await users.createUserDoc(user: newUser)
            } catch {
                print("FIRESTORE WRITE ERROR:", error)
                let ns = error as NSError
                print("Domain:", ns.domain, "Code:", ns.code, "Info:", ns.userInfo)
                state = .error("Firestore error (\(ns.code)): \(ns.localizedDescription)")
                return
            }

            state = .onboarding(newUser)

        } catch {
            print("AUTH SIGN UP ERROR:", error)
            let ns = error as NSError
            print("Domain:", ns.domain, "Code:", ns.code, "Info:", ns.userInfo)

            // error debugging for firestore
            if let authCode = AuthErrorCode(rawValue: ns.code) {
                state = .error("Auth error (\(authCode)): \(ns.localizedDescription)")
            } else {
                state = .error("Auth error (\(ns.code)): \(ns.localizedDescription)")
            }
        }
    }

    // Marks onboarding as complete
    func completeOnboarding() async {
        guard let uid = auth.currentUID() else {
            state = .signedOut
            return
        }

        do {
            try await users.setNeedsOnboarding(uid: uid, value: false)
            let refreshed = try await users.fetchUser(uid: uid)
            state = .active(refreshed)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // Signs out the current user
    func signOut() {
        do {
            try auth.signOut()
            state = .signedOut
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
