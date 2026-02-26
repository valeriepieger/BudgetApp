//
//  AddAccount.swift
//  BudgetApp
//
//  Created by Valerie on 2/25/26.
//

import SwiftUI

struct AddConnection: View {
    @State private var availableAccounts: [AvailableAccount] = [
        AvailableAccount(name: "Chase Checking", logo: "dollarsign.bank.building", type: "Bank"),
        AvailableAccount(name: "Bank of America", logo: "dollarsign.bank.building", type: "Bank"),
        AvailableAccount(name: "American Express", logo: "creditcard", type: "Credit Card"),
        AvailableAccount(name: "Capital One Credit", logo: "creditcard", type: "Credit Card"),
        AvailableAccount(name: "PayPal", logo: "person.line.dotted.person", type: "Payment Service"),
        AvailableAccount(name: "Venmo", logo: "person.line.dotted.person", type: "Payment Service")
    ]
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            ScrollView {
                VStack() {
                    HeaderWithBack(pageName: "Add Accounts")
                    VStack(alignment: .leading, spacing: 16) {
                        
                        ForEach(availableAccounts) { account in
                            AvailableAccountCard(account: account, themeGreen: .oliveGreen)
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.blue)
                                .font(.system(size: 20))
                            
                            Text("Your financial data is encrypted and secure. We use bank-level security to protect your information and never store your login credentials.")
                                .font(.caption)
                                .foregroundColor(Color(red: 30/255, green: 58/255, blue: 138/255))
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(16)
                    }
                    .padding()
                }
            }
        }
    }
}

struct AvailableAccountCard: View {
    let account: AvailableAccount
    let themeGreen: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Logo
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: account.logo))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(account.type)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                //TODO: connect
            }) {
                Text("Connect")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(themeGreen)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    AddConnection()
}
