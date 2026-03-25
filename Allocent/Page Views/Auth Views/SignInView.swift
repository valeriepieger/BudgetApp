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

    init(session: SessionViewModel) {
        _vm = StateObject(wrappedValue: SignInViewModel(session: session))
    }

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {

                HeaderWithSubtitle(
                    title: "Sign In",
                    subtitle: "Welcome back!"
                )

                VStack(spacing: 18) {

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.footnote)
                            .foregroundColor(.gray)

                        TextField("name@example.com", text: $vm.form.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.footnote)
                            .foregroundColor(.gray)

                        SecureField("Password", text: $vm.form.password)
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
                        Text(vm.isLoading ? "Signing In..." : "Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color("OliveGreen"))
                            .cornerRadius(16)
                    }
                    .disabled(vm.isLoading)
                    .padding(.top, 8)
                }

                HStack(spacing: 4) {
                    Text("Don’t have an account?")
                        .foregroundColor(.gray)
                    NavigationLink("Sign Up") {
                        SignUpView(session: session)
                    }
                    .fontWeight(.semibold)
                }
                .font(.footnote)

                Spacer()
            }
            .padding(.horizontal, 23) // controls horizontal spacing
            .padding(.top, 12)
        }
    }
}
#Preview {
    NavigationStack {
        SignInView(session: SessionViewModel())
            .environmentObject(SessionViewModel())
    }
}
