import SwiftUI
import FirebaseFirestore
import FirebaseAuth

private func optionalFirestoreDouble(_ value: Any?) -> Double? {
    guard let v = value, !(v is NSNull) else { return nil }
    if let d = v as? Double { return d }
    if let n = v as? NSNumber { return n.doubleValue }
    if let i = v as? Int { return Double(i) }
    if let i = v as? Int64 { return Double(i) }
    return nil
}

private enum ExpenseFormField: Hashable {
    case amount, note
}

struct ExpensesView: View {
    @FocusState private var focusedField: ExpenseFormField?
    @State private var amountText: String = ""
    @State private var selectedCategory: BudgetCategory?
    @State private var selectedDate: Date = Date()
    @State private var note: String = ""
    @State private var categories: [BudgetCategory] = []
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    
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
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    VStack(spacing: 20) {
                        AmountField(
                            amountText: $amountText,
                            focusedField: $focusedField,
                            field: .amount
                        )
                        CategoryPicker(
                            categories: categories,
                            selectedCategory: $selectedCategory
                        )
                        DateField(selectedDate: $selectedDate)
                        NoteField(
                            note: $note,
                            focusedField: $focusedField,
                            field: .note
                        )
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
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.black : Color.gray.opacity(0.6))
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isSaving)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear(perform: loadCategories)
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
                        colorHex: data["colorHex"] as? String,
                        limitPercent: optionalFirestoreDouble(data["limitPercent"])
                    )
                }
                
                DispatchQueue.main.async {
                    categories = fetched
                    if let current = selectedCategory,
                       let match = fetched.first(where: { $0.id == current.id }) {
                        selectedCategory = match
                    } else if selectedCategory == nil {
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
        focusedField = nil
        
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
                    focusedField = nil
                    isSaving = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    focusedField = nil
                    isSaving = false
                }
            }
        }
    }
}

private struct AmountField: View {
    @Binding var amountText: String
    var focusedField: FocusState<ExpenseFormField?>.Binding
    var field: ExpenseFormField
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount *")
                .font(.subheadline)
            
            HStack {
                Text("$")
                    .foregroundColor(.gray)
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .focused(focusedField, equals: field)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

private struct CategoryPicker: View {
    var categories: [BudgetCategory]
    @Binding var selectedCategory: BudgetCategory?
    
    private func rowLabel(for category: BudgetCategory) -> String {
        let base = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if base.isEmpty {
            return "Unnamed category"
        }
        return base
    }
    
    private var selectionTitle: String {
        guard let c = selectedCategory else { return "Select a category" }
        return rowLabel(for: c)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category *")
                .font(.subheadline)
            
            Picker(selection: $selectedCategory) {
                Text("Select a category")
                    .tag(nil as BudgetCategory?)
                ForEach(categories) { category in
                    Text(rowLabel(for: category))
                        .tag(Optional(category))
                }
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    Text(selectionTitle)
                        .font(.body)
                        .foregroundStyle(selectedCategory == nil ? Color.gray : Color.primary)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            .pickerStyle(.menu)
            .tint(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, -12)
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
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

private struct NoteField: View {
    @Binding var note: String
    var focusedField: FocusState<ExpenseFormField?>.Binding
    var field: ExpenseFormField
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note (optional)")
                .font(.subheadline)
            
            TextField("e.g., Lunch with friends", text: $note, axis: .vertical)
                .focused(focusedField, equals: field)
                .lineLimit(1...3)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    ExpensesView()
}
