//
//  IncomeView.swift
//  BudgetApp
//
//  Created by Valerie on 2/22/26.
//

import SwiftUI

struct IncomeView: View {
    @StateObject private var viewModel = IncomeViewModel()
    @State private var hasAppeared = false
    @State private var showAddIncome = false
    
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            ScrollView {
                HeaderWithBack(categoryName: "Income")
                
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Monthly Income")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("$\(viewModel.totalMonthlyIncome, specifier: "%.2f")")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    
                    Button(action: { showAddIncome = true }) {
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
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    
                    Text("Income Sources")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    if viewModel.incomeSources.isEmpty {
                        Text("No income sources yet. Tap Add Income to get started.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.incomeSources) { source in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(source.name)
                                            .font(.headline)
                                        if let date = source.dateAdded {
                                            Text(formatDate(date))
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    Spacer()
                                    Text("+$\(source.amount, specifier: "%.2f")")
                                        .font(.headline)
                                    
                                    Button(action: {
                                        Task { await viewModel.deleteSource(id: source.id) }
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .padding(.leading, 8)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showAddIncome) {
            AddIncomeSheet(viewModel: viewModel, isPresented: $showAddIncome)
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            viewModel.startListening()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

private struct AddIncomeSheet: View {
    @ObservedObject var viewModel: IncomeViewModel
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var amountText = ""
    @State private var isSaving = false
    
    private var amount: Double {
        Double(amountText) ?? 0
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source name")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("e.g. Salary", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.words)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly amount")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        HStack {
                            Text("$")
                            TextField("0.00", text: $amountText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }
    
    private func save() {
        guard isValid else { return }
        isSaving = true
        Task {
            await viewModel.addSource(name: name.trimmingCharacters(in: .whitespaces), amount: amount)
            await MainActor.run {
                isSaving = false
                isPresented = false
            }
        }
    }
}

#Preview {
    IncomeView()
}
