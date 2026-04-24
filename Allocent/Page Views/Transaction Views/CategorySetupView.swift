import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CategorySetupView: View {
    @EnvironmentObject var session: SessionViewModel
    @State private var selectedCategories: Set<TransactionCategory> = []
    @State private var showEmptyAlert = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Set Up Your Categories")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Select categories to track your spending. You can edit these later in settings.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // selected count
                    Text("\(selectedCategories.count) selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // category grid
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 10) {
                        ForEach(TransactionCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategories.contains(category)
                            ) {
                                withAnimation {
                                    if selectedCategories.contains(category) {
                                        selectedCategories.remove(category)
                                    } else {
                                        selectedCategories.insert(category)
                                    }
                                }
                            }
                        }
                    }

                    // confirm button
                    Button {
                        saveCategories()
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Continue")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedCategories.isEmpty ? Color.gray.opacity(0.3) : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(selectedCategories.isEmpty || isLoading)
                }
                .padding()
            }
            .alert("Select at least one category", isPresented: $showEmptyAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please select at least one category to continue.")
            }
        }
    }

    private func saveCategories() {
        guard !selectedCategories.isEmpty else {
            showEmptyAlert = true
            return
        }

        guard let uid = Auth.auth().currentUser?.uid else { return }

        isLoading = true

        let categoryNames = selectedCategories.map { $0.rawValue }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData(["visibleCategories": categoryNames], merge: true) { error in
                isLoading = false
                if let error = error {
                    print("Error saving categories: \(error.localizedDescription)")
                } else {
                    Task { await self.session.loadSession() }
                }
            }
    }
}
