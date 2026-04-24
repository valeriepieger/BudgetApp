//
//  OnboardingBankLinkStep.swift
//  Allocent
//
//  Created by Valerie on 4/7/26.
//

import SwiftUI
import LinkKit

struct OnboardingBankLinkStep: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    @State private var linkToken: String = ""
    @State private var showPlaid = false
    @State private var isFetchingToken = false
    @State private var isFinishingLink = false
    @State private var localError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderWithSubtitle(
                title: "Link your bank",
                subtitle: "Optional — Plaid imports transactions so this month’s spending can match your categories"
            )
            .padding(.horizontal, 24)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    connectCard

                    if !viewModel.plaidLinksThisSession.isEmpty {
                        linkedSummary
                    }

                    if let localError {
                        Text(localError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    securityNote
                        .padding(.top, 4)

                    Spacer().frame(height: 80)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .scrollIndicators(.hidden)

            bottomNavigation
        }
        .plaidLink(
            isPresented: $showPlaid,
            token: linkToken,
            onSuccess: { success in
                Task { await handlePlaidSuccess(publicToken: success.publicToken) }
            },
            onExit: { exit in
                showPlaid = false
                if let err = exit.error {
                    localError = String(describing: err)
                }
            },
            onEvent: { _ in },
            onLoad: {},
            errorView: AnyView(plaidErrorFallback)
        )
    }

    // MARK: - Connect

    private var connectCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plaid")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text("Securely connect checking, savings, or credit cards. Your credentials stay with Plaid.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task { await openPlaidLink() }
            } label: {
                HStack {
                    if isFetchingToken || isFinishingLink {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isFetchingToken ? "Opening…" : (isFinishingLink ? "Syncing…" : "Connect with Plaid"))
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color("OliveGreen"))
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 12))
            }
            .disabled(isFetchingToken || isFinishingLink)
        }
        .padding()
        .background(Color("CardBackground"))
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var linkedSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Linked this session")
                .font(.headline)
            ForEach(viewModel.plaidLinksThisSession) { link in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color("OliveGreen"))
                    Text(link.institution ?? "Bank account")
                        .font(.subheadline)
                }
            }
            Text("Transactions will be matched to your category names when you finish setup.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color("OliveGreen").opacity(0.08))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var securityNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(Color("OliveGreen"))
                .font(.system(size: 20))

            Text("Your financial data is encrypted. We never store your bank login — Plaid handles authentication.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color("OliveGreen").opacity(0.08))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var plaidErrorFallback: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
            Text("Plaid couldn’t start from this link token.")
                .multilineTextAlignment(.center)
            Button("Dismiss") {
                showPlaid = false
            }
        }
        .padding()
    }

    // MARK: - Navigation

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

            PrimaryActionButton(title: "Continue") {
                viewModel.goToNext()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    // MARK: - Plaid

    @MainActor
    private func openPlaidLink() async {
        localError = nil
        isFetchingToken = true
        defer { isFetchingToken = false }
        do {
            let token = try await PlaidFunctionsClient.createLinkToken(environment: .current)
            linkToken = token
            showPlaid = true
        } catch {
            localError = error.localizedDescription
        }
    }

    @MainActor
    private func handlePlaidSuccess(publicToken: String) async {
        isFinishingLink = true
        defer {
            isFinishingLink = false
            showPlaid = false
        }
        do {
            let (itemId, institution) = try await PlaidFunctionsClient.exchangePublicToken(
                publicToken,
                environment: .current
            )
            _ = try await PlaidFunctionsClient.syncTransactions(itemId: itemId)
            viewModel.registerPlaidLink(itemId: itemId, institution: institution)
        } catch {
            localError = error.localizedDescription
        }
    }
}

#Preview {
    OnboardingBankLinkStep()
        .environmentObject(OnboardingViewModel())
}
