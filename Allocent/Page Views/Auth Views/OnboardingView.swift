//
//  OnboardingView.swift
//  Allocent
//
//  Created by Amber Liu on 2/26/26.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var session: SessionViewModel
    let user: AppUser

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {

                HeaderWithSubtitle(
                    title: "Welcome, \(user.firstName)",
                    subtitle: "Temporary setup screen"
                )
                .padding(.horizontal, 24)
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 12) {

                    Text("This onboarding screen is temporary.")
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    Text("In the next iteration, this will collect initial income, categories, and bank connections.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button {
                        Task { await session.completeOnboarding() }
                    } label: {
                        Text("Continue to App")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color("OliveGreen"))
                            .cornerRadius(16)
                    }
                    .padding(.top, 8)

                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 24)

                Button {
                    session.signOut()
                } label: {
                    Text("Sign Out")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}

#Preview {
    OnboardingView(
        user: AppUser(
            id: "preview_uid",
            firstName: "Amber",
            lastName: "Liu",
            email: "amber@example.com",
            phoneNumber: "",
            bio: "",
            createdAt: Date(),
            needsOnboarding: true,
            linked: false,
//            lastSyncAt: nil as Date?
        )
    )
    .environmentObject(SessionViewModel())
}
