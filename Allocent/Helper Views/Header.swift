//
//  Header.swift
//  BudgetApp
//
//  Created by Valerie on 2/24/26.
//

import SwiftUI

struct Header: View {
    var categoryName: String
    var body: some View {
        HStack {
            Text(categoryName)
                .font(.title)
                .fontWeight(.medium)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

#Preview {
    Header(categoryName: "Account")
}
