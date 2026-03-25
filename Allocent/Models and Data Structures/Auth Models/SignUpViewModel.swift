//
//  SignUpViewModel.swift
//  Allocent
//
//  Created by Amber Liu on 2/26/26.
//

import Foundation
import Combine

@MainActor
final class SignUpViewModel: ObservableObject {

    @Published var form = SignUpForm()
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let session: SessionViewModel

    init(session: SessionViewModel) {
        self.session = session
    }

    func submit() async {
        errorMessage = nil

        let first = form.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = form.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = form.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = form.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let bio = form.bio.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !first.isEmpty else { errorMessage = "First name is required."; return }
        guard !last.isEmpty else { errorMessage = "Last name is required."; return }
        guard email.contains("@") else { errorMessage = "Enter a valid email."; return }

        // optional: basic phone validation (keep lightweight)
        if !phone.isEmpty && phone.count < 7 {
            errorMessage = "Enter a valid phone number or leave it blank."
            return
        }

        guard form.password.count >= 6 else { errorMessage = "Password must be at least 6 characters."; return }
        guard form.password == form.confirmPassword else { errorMessage = "Passwords do not match."; return }

        isLoading = true
        defer { isLoading = false }

        await session.signUp(
            firstName: first,
            lastName: last,
            email: email,
            phoneNumber: phone,
            bio: bio,
            password: form.password
        )
    }
}
