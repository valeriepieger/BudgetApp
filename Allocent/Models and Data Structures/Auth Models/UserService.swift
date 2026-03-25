//
//  UserService.swift
//  Allocent
//
//  Created by Amber Liu on 2/26/26.
//

import Foundation
import FirebaseFirestore

final class UserService {

    private let db = Firestore.firestore()

    func createUserDoc(user: AppUser) async throws {
        try await db.collection("users").document(user.id).setData([
            "firstName": user.firstName,
            "lastName": user.lastName,
            "email": user.email,
            "phoneNumber": user.phoneNumber,
            "bio": user.bio,

            "createdAt": Timestamp(date: user.createdAt),
            "needsOnboarding": user.needsOnboarding,

            "linked": user.linked
        ])
    }

    func fetchUser(uid: String) async throws -> AppUser {
        let snapshot = try await db.collection("users").document(uid).getDocument()
        guard let data = snapshot.data() else {
            throw NSError(
                domain: "UserService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "User profile not found"]
            )
        }

        let firstName = data["firstName"] as? String ?? ""
        let lastName = data["lastName"] as? String ?? ""
        let email = data["email"] as? String ?? ""
        let phoneNumber = data["phoneNumber"] as? String ?? ""
        let bio = data["bio"] as? String ?? ""

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let needsOnboarding = data["needsOnboarding"] as? Bool ?? true

        let linked = data["linked"] as? Bool ?? false

        return AppUser(
            id: uid,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phoneNumber: phoneNumber,
            bio: bio,
            createdAt: createdAt,
            needsOnboarding: needsOnboarding,
            linked: linked,
//            lastSyncAt: lastSyncAt
        )
    }

    func updateProfile(uid: String,
                       firstName: String,
                       lastName: String,
                       email: String,
                       phoneNumber: String,
                       bio: String) async throws {
        try await db.collection("users").document(uid).setData([
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "phoneNumber": phoneNumber,
            "bio": bio
        ], merge: true)
    }

    func setNeedsOnboarding(uid: String, value: Bool) async throws {
        try await db.collection("users").document(uid).setData([
            "needsOnboarding": value
        ], merge: true)
    }

    func setLinked(uid: String, value: Bool) async throws {
        try await db.collection("users").document(uid).setData([
            "Linked": value
        ], merge: true)
    }

//    func setLastSyncAt(uid: String, date: Date?) async throws {
//        try await db.collection("users").document(uid).setData([
//            "lastSyncAt": date.map { Timestamp(date: $0) } as Any
//        ], merge: true)
//    }
}
