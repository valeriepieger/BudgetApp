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

    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                OnboardingProgressBar(
                    currentStep: viewModel.currentStep.rawValue,
                    totalSteps: viewModel.stepCount
                )
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Step content
                Group {
                    switch viewModel.currentStep {
                    case .welcome:
                        welcomeStep
                    case .income:
                        OnboardingIncomeStep()
                    case .budgetCategories:
                        OnboardingBudgetStep()
                    case .bankLink:
                        OnboardingBankLinkStep()
                    case .completion:
                        OnboardingCompletionStep(user: user)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .environmentObject(viewModel)
    }

    // MARK: - Welcome Step

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer().frame(height: 24)

            Text("Welcome, \(user.firstName)!")
                .font(.largeTitle)
                .bold()
                .padding(.horizontal, 24)

            Text("Let's set up your budget in just a few steps.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            Spacer().frame(height: 16)

            AppCard {
                VStack(alignment: .leading, spacing: 16) {
                    OnboardingBullet(
                        icon: "dollarsign.circle.fill",
                        title: "Add your income",
                        subtitle: "Tell us how much you earn each month"
                    )
                    OnboardingBullet(
                        icon: "chart.pie.fill",
                        title: "Set category limits",
                        subtitle: "Allocate your income across spending categories"
                    )
                    OnboardingBullet(
                        icon: "building.columns.fill",
                        title: "Link your bank",
                        subtitle: "Optionally connect Plaid to import this month’s spending"
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            PrimaryActionButton(title: "Get Started") {
                viewModel.goToNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Progress Bar

private struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep
                          ? Color("OliveGreen")
                          : Color.gray.opacity(0.2))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
}

// MARK: - Onboarding Bullet

private struct OnboardingBullet: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color("OliveGreen"))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
            profileImageURL: nil,
            linked: false
        )
    )
    .environmentObject(SessionViewModel())
}
