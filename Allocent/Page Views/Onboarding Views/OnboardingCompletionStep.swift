//
//  OnboardingCompletionStep.swift
//  Allocent
//
//  Created by Valerie on 4/7/26.
//

import SwiftUI

struct OnboardingCompletionStep: View {
    let user: AppUser
    @EnvironmentObject var session: SessionViewModel
    @EnvironmentObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer().frame(height: 24)

            Text("You're all set!")
                .font(.largeTitle)
                .bold()
                .padding(.horizontal, 24)

            Text("Here's a summary of your budget setup.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            Spacer().frame(height: 8)

            ScrollView {
                VStack(spacing: 16) {
                    incomeSummaryCard
                    categoriesInfoCard
                    Spacer().frame(height: 60)
                }
            }
            .scrollIndicators(.hidden)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 24)
            }

            bottomNavigation
        }
    }


    private var incomeSummaryCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(Color("OliveGreen"))
                    Text("Monthly Income")
                        .font(.headline)
                }

                ForEach(viewModel.incomeSources) { source in
                    HStack {
                        Text(source.name)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("$\(source.amount, specifier: "%.2f")")
                            .font(.subheadline.weight(.medium))
                    }
                }

                Divider()

                HStack {
                    Text("Total")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("$\(viewModel.totalIncome, specifier: "%.2f")/mo")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color("OliveGreen"))
                }
            }
        }
        .padding(.horizontal, 24)
    }


    private var categoriesInfoCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .foregroundStyle(Color("OliveGreen"))
                    Text("Budget Categories")
                        .font(.headline)
                }

                Text("We've set up default spending categories for you:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(Array(viewModel.selectedCategories).sorted { $0.rawValue < $1.rawValue }, id: \.self) { category in
                    HStack(spacing: 8) {
                        Text(category.emoji)
                        Text(category.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                Text("You can customize these anytime in Categories.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24)
    }


    private var bottomNavigation: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.goToPrevious()
            } label: {
                Text("Back")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color("CardBackground"))
                    .clipShape(.rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.primary.opacity(0.08), lineWidth: 1)
                    )
            }

            PrimaryActionButton(
                title: "Get Started",
                isLoading: viewModel.isSaving
            ) {
                Task {
                    do {
                        try await viewModel.saveAllData()
                        await session.completeOnboarding()
                    } catch {
                        // errorMessage is set by saveAllData()
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}
