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

    init(session: SessionViewModel) {
        _vm = StateObject(wrappedValue: SignUpViewModel(session: session))
    }

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    HeaderWithSubtitle(
                        title: "Sign Up",
                        subtitle: "Create your account"
                    )

                    VStack(spacing: 18) {

                        VStack(alignment: .leading, spacing: 8) {
                            Text("First Name")
                                .font(.footnote)
                                .foregroundColor(.gray)

                            TextField("First name", text: $vm.form.firstName)
                                .textInputAutocapitalization(.words)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Name")
                                .font(.footnote)
                                .foregroundColor(.gray)

                            TextField("Last name", text: $vm.form.lastName)
                                .textInputAutocapitalization(.words)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.footnote)
                                .foregroundColor(.gray)

                            TextField("Insert email", text: $vm.form.email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bio")
                                .font(.footnote)
                                .foregroundColor(.gray)

                            TextField("Optional", text: $vm.form.bio, axis: .vertical)
                                .lineLimit(3, reservesSpace: true)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.footnote)
                                .foregroundColor(.gray)

                            SecureField("Password", text: $vm.form.password)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.footnote)
                                .foregroundColor(.gray)

                            SecureField("Confirm password", text: $vm.form.confirmPassword)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                        }

                        if let error = vm.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task { await vm.submit() }
                        } label: {
                            Text(vm.isLoading ? "Creating..." : "Create Account")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.black)
                                .cornerRadius(16)
                        }
                        .disabled(vm.isLoading)
                        .opacity(vm.isLoading ? 0.7 : 1)
                        .padding(.top, 6)
                    }

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.gray)
                        NavigationLink("Sign In") {
                            SignInView(session: session)
                        }
                        .fontWeight(.semibold)
                    }
                    .font(.footnote)

                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
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
