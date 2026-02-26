//
//  CategoriesCard.swift
//  BudgetApp
//
//  Created by Valerie on 2/24/26.
//

import SwiftUI

struct CategoriesCard: View {
    var categoryName: String
    @Binding var categoryPercentage: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("" + categoryName)
                    .font(.headline)
                Spacer()
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            
            HStack {
                Text("Percentage:")
                    .foregroundColor(.gray)
                TextField("", text: $categoryPercentage)
                    .keyboardType(.numberPad)
                    .padding(8)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .frame(width: 120)
                Text("%")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    CategoriesCard(categoryName: "Food", categoryPercentage: .constant("25"))
}
