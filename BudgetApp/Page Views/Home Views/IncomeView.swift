//
//  IncomeView.swift
//  BudgetApp
//
//  Created by Valerie on 2/22/26.
//


import SwiftUI

struct IncomeView: View {
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Monthly Income")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        //hard coded for now
                        Text("$1700.00")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .gray, radius: 2)
                    
                    //add income button
                    Button(action: {
                        //TODO: add action
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Income")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("OliveGreen"))
                        .cornerRadius(10)
                    }
                    
                    Text("Income Sources")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    //Ex Income Item hardcoded for now
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Salary")
                                .font(.headline)
                            Text("2026-02-01")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("+$1700.00")
                            .font(.headline)
                        
                        Button(action: {
                            //TODO: add function to include fields to add income when button pressed
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .padding(.leading, 8)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Income")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    IncomeView()
}
