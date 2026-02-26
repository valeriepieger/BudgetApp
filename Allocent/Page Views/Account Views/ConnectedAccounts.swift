//
//  ConnectedAccounts.swift
//  BudgetApp
//
//  Created by Valerie on 2/25/26.
//


import SwiftUI

struct ConnectedAccount: Identifiable {
    let id: String
    let name: String
    let type: String
    let logo: String
    let status: AccountStatus
    var lastSync: String?
    var accountNumber: String?
    
    enum AccountStatus {
        case connected, error
    }
}

struct AvailableAccount: Identifiable {
    let id = UUID()
    let name: String
    let logo: String
    let type: String
}

struct ConnectedAccountsView: View {
    @Environment(\.dismiss) var dismiss
    
    
    @State private var connectedAccounts: [ConnectedAccount] = [
        ConnectedAccount(id: "1", name: "Chase Checking", type: "Bank Account", logo: "dollarsign.bank.building", status: .connected, lastSync: "2 hours ago", accountNumber: "****4523"),
        ConnectedAccount(id: "2", name: "Capital One Credit", type: "Credit Card", logo: "creditcard", status: .connected, lastSync: "1 day ago", accountNumber: "****8901"),
        ConnectedAccount(id: "3", name: "Wells Fargo Savings", type: "Savings Account", logo: "wallet.bifold", status: .error, lastSync: "5 days ago", accountNumber: "****2341")
    ]
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()
                
                ScrollView {
                    HeaderWithBack(pageName: "Connected Accounts")
                        .padding(.bottom, 24)
                    VStack(alignment: .leading, spacing: 24) {
                        
                        
                        
                        Text("Link your bank accounts and credit cards to automatically track your spending")
                            .foregroundColor(.gray)
                            .padding(.top, -8)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your Accounts")
                                .font(.headline)
                            
                            ForEach(connectedAccounts) { account in
                                ConnectedAccountCard(account: account, themeGreen: .oliveGreen)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Add New Account")
                                .font(.headline)
                            
                            NavigationLink(destination: {
                                AddConnection().navigationBarBackButtonHidden()
                            }) {
                                HStack(spacing: 16) {
                                    Circle()
                                        .fill(.oliveGreen)
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .foregroundColor(.white)
                                                .font(.title3)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Connect Bank Account")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                        Text("Link a checking or savings account")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                        }
                        
                        
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct ConnectedAccountCard: View {
    let account: ConnectedAccount
    let themeGreen: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Logo
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: account.logo))
            
            VStack(alignment: .leading, spacing: 8) {
                // Header row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if let number = account.accountNumber {
                            Text(number)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    HStack(spacing: 4) {
                        if account.status == .connected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                            Text("Connected")
                        } else {
                            Image(systemName: "exclamationmark.circle")
                                .font(.system(size: 12, weight: .bold))
                            Text("Error")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(account.status == .connected ? themeGreen : .red)
                }
                
                // Details row
                Text("\(account.type) · Last sync \(account.lastSync ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Action Buttons
                HStack(spacing: 12) {
                    if account.status == .error {
                        Button("Reconnect") { }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(themeGreen)
                    }
                    
                    Button("Manage") { }
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button("Remove") { }
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ConnectedAccountsView()
}
