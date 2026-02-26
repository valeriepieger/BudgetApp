//
//  HeaderWithBack.swift
//  BudgetApp
//
//  Created by Valerie on 2/24/26.
//


import SwiftUI

struct HeaderWithBack: View {
    var pageName: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.title)
                    .padding(.trailing, 10)
                    .foregroundColor(.black)
            }
            
            Text(pageName)
                .font(.title)
                .fontWeight(.medium)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

#Preview {
    HeaderWithBack(pageName: "Income")
}
