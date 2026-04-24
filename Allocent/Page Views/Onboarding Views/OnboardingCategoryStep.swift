//
//  OnboardingCategoryStep.swift
//  Allocent
//
//  Created by Amber Liu on 4/23/26.
//


import SwiftUI

struct OnboardingCategoryStep: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderWithSubtitle(
                title: "Your Categories",
                subtitle: "Select categories to track your spending. You can add/edit these later."
            )
            .padding(.horizontal, 24)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("\(viewModel.selectedCategories.count) selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 10) {
                        ForEach(TransactionCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: viewModel.selectedCategories.contains(category)
                            ) {
                                withAnimation {
                                    if viewModel.selectedCategories.contains(category) {
                                        viewModel.selectedCategories.remove(category)
                                    } else {
                                        viewModel.selectedCategories.insert(category)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 80)
                }
            }
            .scrollIndicators(.hidden)

            bottomNavigation
        }
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
                title: "Next",
                disabled: viewModel.selectedCategories.isEmpty
            ) {
                viewModel.goToNext()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}
