//
//  AccountView.swift
//  BudgetApp
//
//  Created by Valerie on 2/23/26.
//

import SwiftUI

struct AccountView: View {
    @State private var pushNotifications = true
    @State private var budgetAlerts = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()
                
                VStack(spacing: 30) {
                    
                    Header(categoryName: "Account")
                    
                    //Name and email
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color(.oliveGreen.opacity(Double(0.3))))
                            .frame(width: 60, height: 60)
                            .overlay(Image(systemName: "person").foregroundColor(.oliveGreen.opacity(Double(10.0)))).bold(true)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Example Account")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(verbatim: "example@example.com")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        //Profile
                        VStack(spacing: 0) {
                            HStack {
                                Text("Profile")
                                    .font(.title3)
                                    .bold()
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 23)
                            Divider()
                            
                            NavigationLink {
                                EditProfile()
                                    .navigationBarBackButtonHidden()
                            } label: {
                                AccountRowNavigation(title: "Edit Profile", icon: "person")
                            }
                            
                            Divider()
                            NavigationLink {
                                EmailPreferencesView()
                                    .navigationBarBackButtonHidden()
                            } label: {
                                AccountRowNavigation(title: "Email Preferences", icon: "envelope")
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(9)
                        .padding(.horizontal)
                        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                        
                        //Settings
                        VStack(spacing: 0) {
                            HStack {
                                Text("Settings")
                                    .font(.title3)
                                    .bold()
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 23)
                            Divider()
                            AccountRowToggle(title: "Push Notifications", icon: "bell", isOn: $pushNotifications)
                            Divider()
                            AccountRowToggle(title: "Budget Alerts", icon: "bell.badge", isOn: $budgetAlerts)
                            Divider()
                            NavigationLink {
                                ConnectedAccountsView()
                                    .navigationBarBackButtonHidden()
                            } label: {
                                AccountRowNavigation(title: "Connected Accounts", icon: "creditcard")
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(9)
                        .padding()
                        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                        
                        //Support
                        VStack(spacing: 0) {
                            HStack {
                                Text("Support")
                                    .font(.title3)
                                    .bold()
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 23)
                            Divider()
                            AccountRowNavigation(title: "FAQ", icon: "questionmark.circle")
                            Divider()
                            AccountRowNavigation(title: "Privacy Policy", icon: "lock.shield")
                            Divider()
                            AccountRowNavigation(title: "Terms of Service", icon: "doc.text")
                        }
                        .background(Color.white)
                        .cornerRadius(9)
                        .padding(.horizontal)
                        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                        
                        Button(action: {
                            //TODO: add log out action
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Log Out")
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red, lineWidth: 0.4))
                        }
                        .padding()
                    }
                    //                    .padding(.horizontal)
                }
            }
        }
    }
}

// Helper views for the Account Page rows
struct AccountRowNavigation: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color(.black))
            Text(title)
                .foregroundStyle(Color(.black))
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct AccountRowToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
//                .fontWeight(.)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.black)
        }
        .padding()
    }
}

#Preview {
    AccountView()
}
