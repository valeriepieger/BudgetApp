//
//  SignInView.swift
//  Allocent
//
//  Created by Amber Liu on 2/26/26.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var session: SessionViewModel
    @StateObject private var vm: SignInViewModel
    @State private var showPassword = false

    init(session: SessionViewModel) {
        _vm = StateObject(wrappedValue: SignInViewModel(session: session))
    }

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome Back")
                            .font(.largeTitle)
                            .bold()

                        Text("Sign in to continue your financial journey")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 18) {
                        LabeledField(label: "Email") {
                            TextField(text: $vm.form.email) {
                                Text(verbatim: "name@example.com")
                            }
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                        }

                        LabeledField(label: "Password") {
                            HStack {
                                Group {
                                    if showPassword {
                                        TextField("Enter your password", text: $vm.form.password)
                                    } else {
                                        SecureField("Enter your password", text: $vm.form.password)
                                    }
                                }
                                .textInputAutocapitalization(.never)

                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundStyle(Color(.primaryButton))
                                }
                                .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                            }
                        }

                        // Forgot Password
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                Task { await forgotPassword() }
                            }
                            .font(.footnote)
                            .foregroundStyle(Color("OliveGreen"))
                        }
                    }

                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    PrimaryActionButton(
                        title: "Sign In",
                        isLoading: vm.isLoading
                    ) {
                        Task { await vm.submit() }
                    }

                    //or continue with
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .frame(height: 1)
                        Text("Or continue with")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .frame(height: 1)
                    }

                    Button {
                        Task { await session.signInWithGoogle() }
                    } label: {
                        HStack(spacing: 10) {
//                            Image("GoogleImage")
//                                .font(.title3)
                            Image("GoogleImage")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                            Text(verbatim: "Google")
                                .font(.subheadline)
                                .foregroundStyle(Color(.primaryButton))
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color("CardBackground"))
                        .clipShape(.rect(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.primary.opacity(0.1), lineWidth: 1)
                        )
                    }

                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundStyle(.secondary)
                        NavigationLink("Sign Up") {
                            SignUpView(session: session)
                        }
                        .foregroundStyle(Color("OliveGreen"))
                        .fontWeight(.semibold)
                    }
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .center)

                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
            .scrollIndicators(.hidden)
        }
    }





    private func forgotPassword() async {
        let email = vm.form.email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard email.contains("@") else {
            vm.errorMessage = "Enter your email above, then tap Forgot Password."
            return
        }
        do {
            try await AuthService().sendPasswordReset(email: email)
            vm.errorMessage = "Password reset email sent to \(email)."
        } catch {
            vm.errorMessage = error.localizedDescription
        }
    }
}


struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)

            content
                .padding()
                .background(Color("CardBackground"))
                .clipShape(.rect(cornerRadius: 12))
        }
    }
}

#Preview {
    NavigationStack {
        SignInView(session: SessionViewModel())
            .environmentObject(SessionViewModel())
    }
}
