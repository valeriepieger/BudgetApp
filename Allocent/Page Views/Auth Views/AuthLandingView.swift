//
//  AuthLandingView.swift
//  Allocent
//
//  Created by Amber Liu on 2/26/26.
//

import SwiftUI

struct AuthLandingView: View {
    @EnvironmentObject var session: SessionViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()

//                ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Image("IconImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .frame(maxWidth: .infinity)
                        .shadow(radius: 1, x: 2, y: 3)
                        .padding(.top, 20)

                    Text("Welcome to Allocent")
                        .font(.largeTitle)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)

                    // Feature highlights
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Smart Allocation of Every Cent")
                            .font(.title3)
                            .bold()
                            .frame(maxWidth: .infinity)

                        Text("Track spending against zero-based budgets and achieve your financial goals with AI-powered guidance")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        VStack(spacing: 10) {
                            FeatureRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Smart Tracking",
                                description: "Automatically categorize expenses and visualize your spending patterns"
                            )
                            FeatureRow(
                                icon: "sparkles",
                                title: "AI Financial Advisor",
                                description: "Get personalized advice and insights powered by artificial intelligence"
                            )
                            FeatureRow(
                                icon: "target",
                                title: "Goal Setting",
                                description: "Set financial goals and track your progress with actionable steps"
                            )
//                            FeatureRow(
//                                icon: "lock.shield",
//                                title: "Bank-Level Security",
//                                description: "Your financial data is encrypted and protected with industry-leading security"
//                            )
                        }
                        .padding(.top, 4)
                    }
                    
                    Spacer().frame(height: 2)

//                    Text("Start allocating your cents:")
//                        .font(.headline)
//                        .foregroundStyle(.primary)
//                        .padding(.leading, 7)
////                        .frame(maxWidth: .infinity)
                        

                    VStack(spacing: 12) {
                        
                        NavigationLink {
                            SignUpView(session: session)
                        } label: {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundStyle(Color("PrimaryButtonText"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color("OliveGreen"))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.primary.opacity(0.08), lineWidth: 1)
                                )
                                .shadow(radius: 1, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            SignInView(session: session)
                        } label: {
                            Text("I Already Have an Account")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color("CardBackground"))
                                .cornerRadius(16)
                                .shadow(radius: 1, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)

                    }

                    Spacer().frame(height: 10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                }
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color("OliveGreen"))
                .frame(width: 40, height: 40)
                .background(Color("OliveGreen").opacity(0.1))
                .clipShape(.rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color("CardBackground"))
        .clipShape(.rect(cornerRadius: 12))
    }
}

#Preview {
    AuthLandingView()
        .environmentObject(SessionViewModel())
}
