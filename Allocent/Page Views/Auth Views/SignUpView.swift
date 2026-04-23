//
//  SignUpView.swift
//  Allocent
//
//  Created by Amber Liu on 2/26/26.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var session: SessionViewModel
    @StateObject private var vm: SignUpViewModel
    @State private var showPassword1 = false
    @State private var showPassword2 = false

    init(session: SessionViewModel) {
        _vm = StateObject(wrappedValue: SignUpViewModel(session: session))
    }

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Account")
                            .font(.largeTitle)
                            .bold()

                        Text("Start your financial journey with Allocent")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 18) {
                        HStack(spacing: 12) {
                            LabeledField(label: "First Name") {
                                TextField("First name", text: $vm.form.firstName)
                                    .textInputAutocapitalization(.words)
                            }

                            LabeledField(label: "Last Name") {
                                TextField("Last name", text: $vm.form.lastName)
                                    .textInputAutocapitalization(.words)
                            }
                        }

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
                                    if showPassword1 {
                                        TextField("Create a password", text: $vm.form.password)
                                    } else {
                                        SecureField("Create a password", text: $vm.form.password)
                                    }
                                }
                                .textInputAutocapitalization(.never)

                                Button {
                                    showPassword1.toggle()
                                } label: {
                                    Image(systemName: showPassword1 ? "eye.slash" : "eye")
                                        .foregroundStyle(Color(.primaryButton))
                                }
                                .accessibilityLabel(showPassword1 ? "Hide password" : "Show password")
                            }
                        }

                        LabeledField(label: "Confirm Password") {
                            HStack {
                                Group {
                                    if showPassword2 {
                                        TextField("Confirm your password", text: $vm.form.confirmPassword)
                                    } else {
                                        SecureField("Confirm your password", text: $vm.form.confirmPassword)
                                            .textInputAutocapitalization(.never)
                                    }
                                }
                                .textInputAutocapitalization(.never)

                                Button {
                                    showPassword2.toggle()
                                } label: {
                                    Image(systemName: showPassword2 ? "eye.slash" : "eye")
                                        .foregroundStyle(Color(.primaryButton))
                                }
                                .accessibilityLabel(showPassword2 ? "Hide password" : "Show password")
                            }
                        }
                    }

                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    PrimaryActionButton(
                        title: "Create Account",
                        isLoading: vm.isLoading
                    ) {
                        Task { await vm.submit() }
                    }

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
                        Text("Already have an account?")
                            .foregroundStyle(.secondary)
                        NavigationLink("Sign In") {
                            SignInView(session: session)
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
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SignUpView(session: SessionViewModel())
            .environmentObject(SessionViewModel())
    }
}
