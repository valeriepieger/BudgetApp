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
    @State private var plaidHandler: Handler?
    @State private var isFetchingToken = false
    @State private var isFinishingLink = false
    @State private var localError: String?
    @State private var debugInfo: String?
    /// Prevents double-taps scheduling two overlapping callable requests (GTMSessionFetcher "already running").
    @State private var linkLaunchInFlight = false

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

                    if let debugInfo {
                        Text(debugInfo)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
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
        .fullScreenCover(isPresented: $showPlaid) {
            plaidSheetContent
        }
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
                guard !linkLaunchInFlight else { return }
                linkLaunchInFlight = true
                Task { @MainActor in
                    defer { linkLaunchInFlight = false }
                    await openPlaidLink()
                }
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
            if let debugInfo {
                Text(debugInfo)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
            }
            Button("Dismiss") {
                showPlaid = false
            }
        }
        .padding()
    }

    @ViewBuilder
    private var plaidSheetContent: some View {
        if let plaidHandler {
            plaidHandler.makePlaidLinkSheet()
        } else {
            plaidErrorFallback
        }
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
        debugInfo = nil
        isFetchingToken = true
        defer { isFetchingToken = false }
        do {
            let token = try await PlaidFunctionsClient.createLinkToken(environment: .current)
            let env = PlaidBackendEnvironment.current.rawValue
            debugInfo = "Token received: prefix=\(token.prefix(5)) length=\(token.count) env=\(env)"
            guard token.hasPrefix("link-"), token.count > 24 else {
                localError = "Received an invalid Plaid link token from backend."
                return
            }
            linkToken = token
            guard configurePlaidHandler(token: token) else {
                return
            }
            showPlaid = true
        } catch {
            localError = error.localizedDescription
            debugInfo = "createLinkToken failed: \(error.localizedDescription)"
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
            debugInfo = "Link success follow-up failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func configurePlaidHandler(token: String) -> Bool {
        var configuration = LinkTokenConfiguration(token: token) { success in
            Task { await handlePlaidSuccess(publicToken: success.publicToken) }
        }

        configuration.onExit = { exit in
            showPlaid = false
            if let err = exit.error {
                localError = String(describing: err)
                debugInfo = "Plaid exit error: \(String(describing: err))"
            }
        }

        configuration.onEvent = { event in
            debugInfo = "Plaid event: \(event.eventName)"
        }

        let result = Plaid.create(configuration) {
            debugInfo = (debugInfo ?? "") + " | onLoad"
        }

        switch result {
        case .success(let handler):
            plaidHandler = handler
            return true
        case .failure(let error):
            localError = "Plaid handler creation failed."
            debugInfo = "Plaid.create error: \(error)"
            return false
        }
    }
}

#Preview {
    OnboardingBankLinkStep()
        .environmentObject(OnboardingViewModel())
}
