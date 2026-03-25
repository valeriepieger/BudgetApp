//
//  EditProfile.swift
//  BudgetApp
//
//  Created by Valerie on 2/25/26.
//

import SwiftUI


/*
 example email types that we could offer. was thinking we could use sendgrid like we did with foreign currency website
 for the MFA emails or just using the firebase extension "Trigger Email from Firestore" which uses sendgrid but don't know
 pricing and stuff. going to look more into it - Val
 */

struct EmailPreferencesView: View {
    @Environment(\.dismiss) var dismiss

    @State private var weeklyDigest = true
    @State private var budgetAlerts = true
    @State private var savingsGoals = true
    @State private var billReminders = false
    @State private var tipsAdvice = true
    @State private var productUpdates = false
    @State private var marketingEmails = false
    
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            
            ScrollView {
                VStack {
                    HeaderWithBack (pageName: "Email Preferences")
                    VStack(alignment: .leading, spacing: 24) {
                        
                        
                        Text("Choose what emails you'd like to receive from us!")
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Financial Updates")
                                .font(.headline)
                                .padding(.bottom, 16)
                            
                            PreferenceToggleRow(title: "Weekly Digest", description: "Get a weekly summary of your spending and savings", isOn: $weeklyDigest, showDivider: false)
                            
                            PreferenceToggleRow(title: "Budget Alerts", description: "Notifications when you're close to budget limits", isOn: $budgetAlerts)
                            
                            PreferenceToggleRow(title: "Savings Goals", description: "Updates on your savings progress and milestones", isOn: $savingsGoals)
                            
                            PreferenceToggleRow(title: "Bill Reminders", description: "Reminders for upcoming bills and due dates", isOn: $billReminders)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Content & Features")
                                .font(.headline)
                                .padding(.bottom, 16)
                            
                            PreferenceToggleRow(title: "Tips & Advice", description: "Financial tips and money-saving strategies", isOn: $tipsAdvice, showDivider: false)
                            
                            PreferenceToggleRow(title: "Product Updates", description: "New features and improvements to the app", isOn: $productUpdates)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Marketing")
                                .font(.headline)
                                .padding(.bottom, 16)
                            
                            PreferenceToggleRow(title: "Promotional Emails", description: "Special offers and partner promotions", isOn: $marketingEmails, showDivider: false)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        Button(action: {
                            //TODO: need to handle save action
                            dismiss()
                        }) {
                            Text("Save Preferences")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color("OliveGreen"))
                                .cornerRadius(16)
                        }
                        .padding(.top, 8)
                        
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }
}


struct PreferenceToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    var showDivider: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            if showDivider {
                Divider()
                    .padding(.vertical, 16)
            }
            
            Toggle(isOn: $isOn) {
                VStack(alignment: .leading, spacing: 15) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(.black)
        }
    }
}

#Preview {
    EmailPreferencesView()
}
