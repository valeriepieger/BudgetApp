//
//  AddTransactionView.swift
//  Allocent
//
//  Created by Amber Liu on 4/2/26.
//

import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var merchant = ""
    @State private var amount = ""
    @State private var date = Date.now
    @State private var category: TransactionCategory = .other
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var amountValue: Double? {
        Double(amount.replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespaces))
    }

    private var isValid: Bool {
        !merchant.trimmingCharacters(in: .whitespaces).isEmpty &&
        amountValue != nil &&
        amountValue! > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Merchant name", text: $merchant)

                    HStack {
                        Text("$").foregroundStyle(.secondary)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Category") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(TransactionCategory.allCases, id: \.self) { cat in
                            CategoryChip(category: cat, isSelected: category == cat) {
                                category = cat
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Notes (optional)") {
                    TextField("Add a note...", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.circle")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .bold()
                        .disabled(!isValid || isSaving)
                }
            }
        }
    }

    private func save() async {
        guard isValid, let value = amountValue else { return }
        isSaving = true
        let transaction = Transaction(
            merchant: merchant.trimmingCharacters(in: .whitespaces),
            amount: value,
            date: date,
            category: category,
            notes: notes
        )
        do {
            try await TransactionService.add(transaction)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

struct CategoryChip: View {
    let category: TransactionCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(category.emoji)
                Text(category.rawValue)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemGroupedBackground))
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }
}
