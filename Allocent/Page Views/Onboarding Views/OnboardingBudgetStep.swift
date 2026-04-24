//
//  OnboardingBudgetStep.swift
//  Allocent
//
//  Created by Valerie on 4/9/26.
//

import SwiftUI

struct OnboardingBudgetStep: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderWithSubtitle(
                title: "Budget Categories",
                subtitle: "Set a monthly budget for each category"
            )
            .padding(.horizontal, 24)

            IncomeSummaryHeader(
                totalIncome: viewModel.totalIncome,
                totalAllocated: viewModel.totalAllocated,
                isOverAllocated: viewModel.isOverAllocated
            )
            .padding(.horizontal, 24)
            .padding(.top, 12)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(TransactionCategory.allCases, id: \.self) { category in
                        BudgetCategoryRow(
                            category: category,
                            amount: Binding(
                                get: { viewModel.categoryAllocations[category] ?? 0 },
                                set: { viewModel.updateAllocation(for: category, amount: $0) }
                            )
                        )
                    }
                    Spacer().frame(height: 80)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .scrollIndicators(.hidden)

            OnboardingBudgetBottomNav()
        }
    }
}

// MARK: - Income Summary Header

private struct IncomeSummaryHeader: View {
    let totalIncome: Double
    let totalAllocated: Double
    let isOverAllocated: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Income")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(totalIncome, format: .currency(code: "USD"))
                    .font(.headline)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Allocated")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(totalAllocated, format: .currency(code: "USD"))
                    .font(.headline)
                    .foregroundStyle(isOverAllocated ? .red : Color("OliveGreen"))
            }
        }
    }
}

// MARK: - Budget Category Row

private struct BudgetCategoryRow: View {
    let category: TransactionCategory
    @Binding var amount: Double
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.iconName)
                .font(.title3)
                .foregroundStyle(Color("OliveGreen"))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.headline)
                HStack(spacing: 4) {
                    Text("$")
                        .foregroundStyle(.secondary)
                    TextField("0", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .frame(width: 80)
                    Text("/mo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color("CardBackground"))
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Bottom Navigation

private struct OnboardingBudgetBottomNav: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    private var remaining: Double {
        viewModel.totalIncome - viewModel.totalAllocated
    }

    var body: some View {
        VStack(spacing: 8) {
            if !viewModel.isBudgetFullyAllocated && viewModel.totalIncome > 0 {
                Text(remaining > 0
                     ? "$\(remaining, specifier: "%.2f") left to allocate"
                     : "Over-allocated by $\(abs(remaining), specifier: "%.2f")")
                    .font(.caption)
                    .foregroundStyle(remaining > 0 ? Color.secondary : Color.red)
            }

            HStack(spacing: 12) {
                Button(action: viewModel.goToPrevious) {
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
                    disabled: !viewModel.isBudgetFullyAllocated
                ) {
                    viewModel.goToNext()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}

#Preview {
    OnboardingBudgetStep()
        .environmentObject(OnboardingViewModel())
}
