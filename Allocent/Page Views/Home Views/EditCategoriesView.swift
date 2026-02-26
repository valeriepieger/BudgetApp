//
//  EditCategoriesView.swift
//  BudgetApp
//
//  Created by Valerie on 2/23/26.
//

import SwiftUI

struct EditCategoriesView: View {
    @StateObject private var viewModel = EditCategoriesViewModel()
    @State private var hasAppeared = false
    @State private var showAddCategory = false
    
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            VStack {
                HeaderWithBack(pageName: "Edit Categories")
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Left to Budget")
                            .foregroundColor(.gray)
                        Text("$\(viewModel.leftToBudget, specifier: "%.2f")")
                            .font(.title)
                            .fontWeight(.bold)
                        Text(viewModel.allocationPercentText)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Allocation Method")
                                .font(.headline)
                            Text("Dollar-based (limit per category)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    
                    HStack {
                        Text("Categories")
                            .font(.headline)
                        Spacer()
                        Button(action: { showAddCategory = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(Color("OliveGreen"))
                        }
                    }
                    
                    ScrollView {
                        if viewModel.categories.isEmpty {
                            Text("No categories yet. Tap Add to create one.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.vertical, 24)
                                .frame(maxWidth: .infinity)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(viewModel.categories) { category in
                                    EditCategoryRow(
                                        category: category,
                                        totalIncome: viewModel.totalIncome,
                                        onSave: { name, limit in
                                            Task { await viewModel.updateCategory(id: category.id, name: name, limit: limit) }
                                        },
                                        onDelete: {
                                            Task { await viewModel.deleteCategory(id: category.id) }
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategorySheet(viewModel: viewModel, isPresented: $showAddCategory)
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            viewModel.startListening()
        }
    }
}

private struct EditCategoryRow: View {
    let category: BudgetCategory
    let totalIncome: Double
    let onSave: (String, Double) -> Void
    let onDelete: () -> Void
    
    @State private var name: String = ""
    @State private var limitText: String = ""
    @State private var isEditing = false
    
    private var limit: Double {
        Double(limitText) ?? 0
    }
    
    private var percentageText: String {
        guard totalIncome > 0, limit > 0 else { return "" }
        let pct = (limit / totalIncome) * 100
        return String(format: "%.0f%% of income", pct)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if isEditing {
                    TextField("Category name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(.headline)
                } else {
                    Text(category.name)
                        .font(.headline)
                }
                Spacer()
                Button(action: {
                    if isEditing {
                        onSave(name.isEmpty ? category.name : name, limit)
                    } else {
                        name = category.name
                        limitText = String(format: "%.2f", category.limit)
                    }
                    isEditing.toggle()
                }) {
                    Text(isEditing ? "Done" : "Edit")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color("OliveGreen"))
                }
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            HStack {
                Text("Monthly limit:")
                    .foregroundColor(.gray)
                if isEditing {
                    HStack(spacing: 4) {
                        Text("$")
                        TextField("0.00", text: $limitText)
                            .keyboardType(.decimalPad)
                            .padding(8)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                            .frame(width: 100)
                    }
                } else {
                    Text("$\(category.limit, specifier: "%.2f")")
                        .font(.subheadline.weight(.medium))
                }
                if !percentageText.isEmpty {
                    Text(percentageText)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        .onAppear {
            name = category.name
            limitText = String(format: "%.2f", category.limit)
        }
    }
}

private struct AddCategorySheet: View {
    @ObservedObject var viewModel: EditCategoriesViewModel
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var limitText = ""
    @State private var isSaving = false
    
    private var limit: Double {
        Double(limitText) ?? 0
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && limit >= 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category name")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("e.g. Food, Bills", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.words)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly limit ($)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("0.00", text: $limitText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add Category")
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
            await viewModel.addCategory(name: name.trimmingCharacters(in: .whitespaces), limit: limit)
            await MainActor.run {
                isSaving = false
                isPresented = false
            }
        }
    }
}

#Preview {
    EditCategoriesView()
}
