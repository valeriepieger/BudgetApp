//
//  OnboardingViewModel.swift
//  Allocent
//
//  Created by Valerie on 4/7/26.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {


    enum Step: Int, CaseIterable {
        case welcome = 0
        case income = 1
        case bankLink = 2
        case completion = 3
    }

    @Published var currentStep: Step = .welcome


    @Published var incomeSources: [DraftIncome] = []
    @Published var newIncomeName: String = ""
    @Published var newIncomeAmount: Double?


    @Published var isSaving: Bool = false
    @Published var errorMessage: String?


    struct DraftIncome: Identifiable {
        let id = UUID()
        var name: String
        var amount: Double
    }


    var totalIncome: Double {
        incomeSources.reduce(0) { $0 + $1.amount }
    }

    var canProceedFromIncome: Bool {
        !incomeSources.isEmpty
    }

    var canAddIncome: Bool {
        let trimmed = newIncomeName.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && (newIncomeAmount ?? 0) > 0
    }

    var stepCount: Int {
        Step.allCases.count
    }


    func goToNext() {
        guard let next = Step(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = next
        }
    }

    func goToPrevious() {
        guard let prev = Step(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = prev
        }
    }


    func addIncome() {
        let trimmed = newIncomeName.trimmingCharacters(in: .whitespaces)
        guard let amount = newIncomeAmount, amount > 0, !trimmed.isEmpty else { return }
        incomeSources.append(DraftIncome(name: trimmed, amount: amount))
        newIncomeName = ""
        newIncomeAmount = nil
    }

    func removeIncome(id: UUID) {
        incomeSources.removeAll { $0.id == id }
    }


    func saveAllData() async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "OnboardingViewModel", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }

        isSaving = true
        errorMessage = nil

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)

        do {
            let batch = db.batch()

            //write income sources
            for source in incomeSources {
                let ref = userRef.collection("income_sources").document()
                batch.setData([
                    "name": source.name,
                    "amount": source.amount,
                    "dateAdded": FieldValue.serverTimestamp()
                ], forDocument: ref)
            }

            //write hardcoded categories from TransactionCategory
            for category in TransactionCategory.allCases {
                let ref = userRef.collection("categories").document()
                batch.setData([
                    "name": category.rawValue,
                    "limit": 0.0
                ], forDocument: ref)
            }

            try await batch.commit()
            isSaving = false
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
