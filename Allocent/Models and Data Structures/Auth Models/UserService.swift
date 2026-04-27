//
//  UserService.swift
//  Allocent
//
//  Created by Amber Liu on 2/26/26.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

final class UserService {

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    func createUserDoc(user: AppUser) async throws {
        var data: [String: Any] = [
            "firstName": user.firstName,
            "lastName": user.lastName,
            "email": user.email,
            "phoneNumber": user.phoneNumber,
            "bio": user.bio,
            "createdAt": Timestamp(date: user.createdAt),
            "needsOnboarding": user.needsOnboarding,
            "linked": user.linked
        ]
        if let url = user.profileImageURL {
            data["profileImageURL"] = url
        }
        try await db.collection("users").document(user.id).setData(data)
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

        let profileImageURL = data["profileImageURL"] as? String

        return AppUser(
            id: uid,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phoneNumber: phoneNumber,
            bio: bio,
            createdAt: createdAt,
            needsOnboarding: needsOnboarding,
            profileImageURL: profileImageURL,
            linked: linked
        )
    }

    func updateProfile(uid: String,
                       firstName: String,
                       lastName: String,
                       email: String,
                       phoneNumber: String,
                       bio: String,
                       profileImageURL: String? = nil) async throws {
        var data: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "phoneNumber": phoneNumber,
            "bio": bio
        ]
        if let url = profileImageURL {
            data["profileImageURL"] = url
        }
        try await db.collection("users").document(uid).setData(data, merge: true)
    }

    func uploadProfileImage(uid: String, imageData: Data) async throws -> String {
        //make a new unique ID for the picture because if just overwriting, will not update on account page even w/ async
        let uniqueID = UUID().uuidString
        let ref = storage.reference().child("profile_images/\(uid)_\(uniqueID).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putData(imageData, metadata: metadata)

        //retry downloadURL
        var lastError: Error?
        for attempt in 0..<3 {
            do {
                if attempt > 0 {
                    try await Task.sleep(for: .seconds(1))
                }
                let url = try await ref.downloadURL()
                // Cache-bust so AsyncImage reloads the updated image
                return url.absoluteString + "&v=\(Int(Date().timeIntervalSince1970))"
            } catch {
                lastError = error
            }
        }
        throw lastError ?? NSError(
            domain: "UserService", code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL after upload."]
        )
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
