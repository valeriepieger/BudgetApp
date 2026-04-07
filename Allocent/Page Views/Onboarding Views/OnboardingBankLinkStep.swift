//
//  OnboardingBankLinkStep.swift
//  Allocent
//
//  Created by Valerie on 4/7/26.
//

import SwiftUI

struct OnboardingBankLinkStep: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    private let availableAccounts: [AvailableAccount] = [
        AvailableAccount(name: "Chase Checking", logo: "dollarsign.bank.building", type: "Bank"),
        AvailableAccount(name: "Bank of America", logo: "dollarsign.bank.building", type: "Bank"),
        AvailableAccount(name: "American Express", logo: "creditcard", type: "Credit Card"),
        AvailableAccount(name: "Capital One Credit", logo: "creditcard", type: "Credit Card"),
        AvailableAccount(name: "PayPal", logo: "person.line.dotted.person", type: "Payment Service"),
        AvailableAccount(name: "Venmo", logo: "person.line.dotted.person", type: "Payment Service")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderWithSubtitle(
                title: "Link a Bank Account",
                subtitle: "Optional — you can always do this later"
            )
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(availableAccounts) { account in
                        bankAccountRow(account)
                    }

                    securityNote
                        .padding(.top, 8)

                    Spacer().frame(height: 80)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .scrollIndicators(.hidden)

            bottomNavigation
        }
    }

    // MARK: - Bank Account Row

    private func bankAccountRow(_ account: AvailableAccount) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: account.logo)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(account.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                // TODO: Connect bank account
            } label: {
                Text("Connect")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color("OliveGreen"))
                    .clipShape(.rect(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color("CardBackground"))
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Security Note

    private var securityNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(Color("OliveGreen"))
                .font(.system(size: 20))

            Text("Your financial data is encrypted and secure. We never store your login credentials.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color("OliveGreen").opacity(0.08))
        .clipShape(.rect(cornerRadius: 12))
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

            PrimaryActionButton(title: "Skip for Now") {
                viewModel.goToNext()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}
