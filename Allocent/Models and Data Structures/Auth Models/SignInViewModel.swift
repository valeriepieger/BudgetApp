//
//  SignInViewModel.swift
//  Allocent
//
//  Created by Amber Liu on 2/26/26.
//

import Foundation
import Combine

@MainActor
final class SignInViewModel: ObservableObject {
    @Published var form = SignInForm()
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let session: SessionViewModel

    init(session: SessionViewModel) {
        self.session = session
    }

    func submit() async {
        errorMessage = nil

        let email = form.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = form.password

        guard email.contains("@") else {
            errorMessage = "Enter a valid email."
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        isLoading = true
        defer { isLoading = false }

        await session.signIn(email: email, password: password)
    }
}
