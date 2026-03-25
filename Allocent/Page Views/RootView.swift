//
//  ContentView.swift
//  BudgetApp
//
//  Created by Valerie on 2/18/26.
//

import SwiftUI

struct RootView: View {
    @StateObject private var session = SessionViewModel()

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            Group {
                switch session.state {
                case .loading:
                    AppCard {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Loading…")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)

                case .signedOut:
                    AuthLandingView()

                case .onboarding(let user):
                    OnboardingView(user: user)

                case .active:
                    NavigationStack {
                        AllTabsView()
                    }
                    .environmentObject(session)

                case .error(let message):
                    AppCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Error")
                                .font(.headline)

                            Text(message)
                                .foregroundStyle(.secondary)

                            Button("Try Again") {
                                Task { await session.loadSession() }
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Sign Out") {
                                session.signOut()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .environmentObject(session)
        }
        .task {
            await session.loadSession()
        }
    }
}

#Preview {
    RootView()
}
