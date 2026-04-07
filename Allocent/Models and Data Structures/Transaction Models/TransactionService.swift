//
//  TransactionService.swift
//  Allocent
//
//  Created by Amber Liu on 4/7/26.
//


import Foundation
import FirebaseFirestore
import FirebaseAuth

struct TransactionService {

    private static func collection() throws -> CollectionReference {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw TransactionServiceError.notAuthenticated
        }
        return Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("transactions")
    }

    static func add(_ transaction: Transaction) async throws {
        try await collection().addDocument(data: transaction.firestoreData)
    }

    static func delete(_ transaction: Transaction) async throws {
        try await collection().document(transaction.id).delete()
    }

    static func fetch() async throws -> [Transaction] {
        let snapshot = try await collection()
            .order(by: "date", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { Transaction.from($0) }
    }
}

enum TransactionServiceError: LocalizedError {
    case notAuthenticated
    var errorDescription: String? { "You must be signed in to access transactions." }
}
