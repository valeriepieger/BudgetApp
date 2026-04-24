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
                            .foregroundStyle(.secondary)
                        Text("$\(viewModel.leftToBudget, specifier: "%.2f")")
                            .font(.title)
                            .fontWeight(.bold)
                        Text(viewModel.allocationPercentText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color("CardBackground"))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Allocation Method")
                                .font(.headline)
                            Text("Dollar-based (limit per category)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color("CardBackground"))
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
                                .foregroundStyle(.secondary)
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
                    .foregroundStyle(.secondary)
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
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color("CardBackground"))
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
    @State private var selected: TransactionCategory? = nil
    @State private var isSaving = false

    private var availableCategories: [TransactionCategory] {
        let existingNames = Set(viewModel.categories.map { $0.name })
        return TransactionCategory.allCases.filter { !existingNames.contains($0.rawValue) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()

                if availableCategories.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color("OliveGreen"))
                        Text("All categories added")
                            .font(.headline)
                        Text("You've added all available categories.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select a category to add")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 10) {
                            ForEach(availableCategories, id: \.self) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: selected == category
                                ) {
                                    selected = category
                                }
                            }
                        }
                        .padding(.horizontal)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        save()
                    }
                    .disabled(selected == nil || isSaving)
                    .bold()
                }
            }
        }
    }

    private func save() {
        guard let category = selected else { return }
        isSaving = true
        Task {
            await viewModel.addCategory(name: category.rawValue, limit: 0.0)
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
