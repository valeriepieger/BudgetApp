import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ExpensesView: View {
    @State private var amountText: String = ""
    @State private var selectedCategory: BudgetCategory?
    @State private var selectedDate: Date = Date()
    @State private var note: String = ""
    @State private var categories: [BudgetCategory] = []
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var showScanReceipt = false

    private var isFormValid: Bool {
        guard Double(amountText) ?? 0 > 0 else { return false }
        return selectedCategory != nil
    }

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Header(categoryName: "Add Expense")

                    Text("Track your spending")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    // Scan Receipt Button
                    Button {
                        showScanReceipt = true
                    } label: {
                        HStack {
                            Image(systemName: "camera")
                            Text("Scan Receipt")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(Color("PrimaryButtonText"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("OliveGreen"))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Divider with "or enter manually" label
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(.secondary.opacity(0.3))
                        Text("or enter manually")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(.secondary.opacity(0.3))
                    }
                    .padding(.horizontal)

                    VStack(spacing: 20) {
                        AmountField(amountText: $amountText)
                        CategoryPicker(
                            categories: categories,
                            selectedCategory: $selectedCategory
                        )
                        DateField(selectedDate: $selectedDate)
                        NoteField(note: $note)
                    }
                    .padding(.horizontal)

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    Button(action: saveExpense) {
                        HStack {
                            if isSaving {
                                ProgressView()
                            }
                            Text("Add Expense")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(Color("PrimaryButtonText"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color("PrimaryButton") : Color("PrimaryButton").opacity(0.4))
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isSaving)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
        }
        .onAppear(perform: loadCategories)
        .sheet(isPresented: $showScanReceipt) {
            ScanReceiptView()
        }
    }

    private func loadCategories() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users")
            .document(uid)
            .collection("categories")
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }

                guard let documents = snapshot?.documents else { return }

                let fetched: [BudgetCategory] = documents.map { doc in
                    let data = doc.data()
                    return BudgetCategory(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "",
                        limit: data["limit"] as? Double ?? 0,
                        colorHex: data["colorHex"] as? String
                    )
                }

                DispatchQueue.main.async {
                    categories = fetched
                    if selectedCategory == nil {
                        selectedCategory = fetched.first
                    }
                }
            }
    }

    private func saveExpense() {
        guard let category = selectedCategory,
              let amount = Double(amountText),
              amount > 0 else { return }

        isSaving = true
        errorMessage = nil

        Task {
            do {
                try await ExpenseService.addExpense(
                    amount: amount,
                    categoryId: category.id,
                    date: selectedDate,
                    note: note.isEmpty ? nil : note
                )
                await MainActor.run {
                    amountText = ""
                    note = ""
                    selectedDate = Date()
                    isSaving = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}

private struct AmountField: View {
    @Binding var amountText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount *")
                .font(.subheadline)

            HStack {
                Text("$")
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
            }
            .padding()
            .background(Color("CardBackground"))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

private struct CategoryPicker: View {
    var categories: [BudgetCategory]
    @Binding var selectedCategory: BudgetCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category *")
                .font(.subheadline)

            Menu {
                ForEach(categories) { category in
                    Button(category.name) {
                        selectedCategory = category
                    }
                }
            } label: {
                HStack {
                    Text(selectedCategory?.name ?? "Select a category")
                        .foregroundStyle(selectedCategory == nil ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color("CardBackground"))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
        }
    }
}

private struct DateField: View {
    @Binding var selectedDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date *")
                .font(.subheadline)

            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .padding()
            .background(Color("CardBackground"))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

private struct NoteField: View {
    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note (optional)")
                .font(.subheadline)

            TextField("e.g., Lunch with friends", text: $note, axis: .vertical)
                .lineLimit(1...3)
                .padding()
                .background(Color("CardBackground"))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    ExpensesView()
}
