//
//  ContentView.swift
//  BudgetApp
//
//  Created by Valerie on 2/18/26.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        VStack(alignment: .leading) {
            //something like
            //if not logged in, navigate to signup/login page
            //if alr authenticated, start at dashboard
            AllTabsView()
        }
    }
}

#Preview {
    RootView()
}
