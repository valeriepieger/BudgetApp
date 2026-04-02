import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var hasAppeared = false
    
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Header(categoryName: "Dashboard")
                    
                    VStack {
                        BudgetDonutChartView(
                            summaries: viewModel.categorySummaries,
                            totalSpent: viewModel.totalSpent
                        )
                        .frame(height: 280)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                    
                    IncomeSummaryCard(totalBudget: viewModel.totalBudget)
                    
                    CategoriesSection(
                        summaries: viewModel.categorySummaries
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            viewModel.startListening()
        }
    }
}

private struct IncomeSummaryCard: View {
    var totalBudget: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Income")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: IncomeView().navigationBarBackButtonHidden(true)) {
                    HStack(spacing: 4) {
                        Text("Manage")
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .font(.subheadline.weight(.medium))
                }
            }
            
            Text("Total Monthly Income")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("$\(totalBudget, specifier: "%.2f")")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
            
            Text("Based on your category limits")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

private struct CategoriesSection: View {
    var summaries: [CategorySummary]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Categories")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: EditCategoriesView().navigationBarBackButtonHidden(true)) {
                    HStack(spacing: 4) {
                        Text("Edit")
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .font(.subheadline.weight(.medium))
                }
            }
            
            if summaries.isEmpty {
                Text("Add categories to start tracking your spending.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(summaries) { summary in
                        CategorySummaryRow(summary: summary)
                    }
                }
            }
        }
    }
}

private struct CategorySummaryRow: View {
    let summary: CategorySummary
    
    private var remainingText: String {
        "$\(summary.left, specifier: "%.2f") left"
    }
    
    private var spentText: String {
        "$\(summary.spent, specifier: "%.2f") of $\(summary.limit, specifier: "%.2f")"
    }
    
    private var progress: Double {
        guard summary.limit > 0 else { return 0 }
        return min(max(summary.spent / summary.limit, 0), 1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(summary.name)
                    .font(.headline)
                Spacer()
                Text(remainingText)
                    .font(.subheadline.weight(.semibold))
            }
            
            Text(spentText)
                .font(.caption)
                .foregroundColor(.gray)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(Color("OliveGreen"))
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    DashboardView()
}

