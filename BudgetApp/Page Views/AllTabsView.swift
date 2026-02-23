//
//  MainTabView.swift
//  BudgetApp
//
//  Created by Valerie on 2/22/26.
//


import SwiftUI

struct AllTabsView: View {
    @State private var selectedTab = 0
    
    init() {
        //for solid white background on nav bar
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            //DASHBOARD PAGE
            NavigationView {
                //TODO: Replace all this with actual dashboard page
                VStack(spacing: 16) {
                    NavigationLink(destination: IncomeView()) {
                        HStack {
                            Spacer()
                            Text("Income page")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(Color.black)
                        .cornerRadius(10)
                    }
                }
                .navigationTitle("Dashboard")
            }
            .tabItem {
                Image(systemName: "house")
                Text("Home")
            }
            .tag(0)
            
            //EXPENSES PAGE
            NavigationView {
                //TODO: replace with actual expenses page
                Text("Expenses view")
                    .navigationTitle("Expenses")
            }
            .tabItem {
                Image(systemName: "plus.circle")
                Text("Expenses")
            }
            .tag(1)
            
            //ADVISOR PAGE
            NavigationView {
                //TODO: replace with actual advisor page
                Text("Advisor Chatbot View")
                    .navigationTitle("Advisor")
            }
            .tabItem {
                Image(systemName: "bubble.right").foregroundStyle(.gray)
                Text("Advisor").foregroundStyle(.gray)
            }
            .tag(2)
            
            //ACCOUNT PAGE
            NavigationView {
                //TODO: replace with actual account page
                Text("Account view")
                    .navigationTitle("Account")
            }
            .tabItem {
                Image(systemName: "person")
                Text("Account")
            }
            .tag(3)
        }
        // This applies your custom green color to the currently selected tab
        .tint(Color("OliveGreen")) 
    }
}

#Preview {
    AllTabsView()
}
