//
//  OnboardingIncomeStep.swift
//  Allocent
//
//  Created by Valerie on 4/7/26.
//

import SwiftUI

struct OnboardingIncomeStep: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderWithSubtitle(
                title: "Your Income",
                subtitle: "Add at least one income source"
            )
            .padding(.horizontal, 24)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    addIncomeCard
                    addedSourcesList
                    Spacer().frame(height: 80)
                }
                .padding(.top, 16)
            }
            .scrollIndicators(.hidden)

            bottomNavigation
        }
    }

    // MARK: - Add Income Card

    private var addIncomeCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Add Income Source")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Source name")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField("e.g. Salary, Freelance", text: $viewModel.newIncomeName)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.words)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Monthly amount")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField("Amount", value: $viewModel.newIncomeAmount, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }

                Button {
                    viewModel.addIncome()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Source")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("OliveGreen"))
                }
                .disabled(!viewModel.canAddIncome)
                .opacity(viewModel.canAddIncome ? 1 : 0.4)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Added Sources List

    @ViewBuilder
    private var addedSourcesList: some View {
        if !viewModel.incomeSources.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Added Sources")
                        .font(.headline)
                    Spacer()
                    Text("$\(viewModel.totalIncome, specifier: "%.2f")/mo")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("OliveGreen"))
                }
                .padding(.horizontal, 24)

                ForEach(viewModel.incomeSources) { source in
                    HStack {
                        Text(source.name)
                            .font(.headline)
                        Spacer()
                        Text("$\(source.amount, specifier: "%.2f")")
                            .font(.subheadline.weight(.medium))
                        Button {
                            viewModel.removeIncome(id: source.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red.opacity(0.7))
                        }
                        .accessibilityLabel("Remove \(source.name)")
                    }
                    .padding()
                    .background(Color("CardBackground"))
                    .clipShape(.rect(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    // MARK: - Bottom Navigation

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
                title: "Next",
                disabled: !viewModel.canProceedFromIncome
            ) {
                viewModel.goToNext()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}
