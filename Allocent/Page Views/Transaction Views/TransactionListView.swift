//
//  TransactionListView.swift
//  Allocent
//
//  Created by Amber Liu on 4/2/26.
//

import SwiftUI

enum TransactionFilter: String, CaseIterable {
    case day = "Day"
    case month = "Month"
    case year = "Year"
    case all = "All"
}

struct TransactionListView: View {
    @State private var transactions: [Transaction] = []
    @State private var showAddManual = false
    @State private var showScanReceipt = false
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedFilter: TransactionFilter = .all

    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date.now

        let dateFiltered: [Transaction]
        switch selectedFilter {
        case .day:
            dateFiltered = transactions.filter { calendar.isDateInToday($0.date) }
        case .month:
            dateFiltered = transactions.filter {
                calendar.isDate($0.date, equalTo: now, toGranularity: .month)
            }
        case .year:
            dateFiltered = transactions.filter {
                calendar.isDate($0.date, equalTo: now, toGranularity: .year)
            }
        case .all:
            dateFiltered = transactions
        }

        guard !searchText.isEmpty else { return dateFiltered }
        return dateFiltered.filter {
            $0.merchant.localizedCaseInsensitiveContains(searchText) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedTransactions: [(String, [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredTransactions) {
            calendar.startOfDay(for: $0.date)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date, transactions) in
                let label = calendar.isDateInToday(date) ? "Today" :
                            calendar.isDateInYesterday(date) ? "Yesterday" :
                            date.formatted(.dateTime.weekday(.wide).month().day())
                return (label, transactions.sorted { $0.date > $1.date })
            }
    }

    private var totalSpend: Double {
        filteredTransactions.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading transactions...")
            } else if filteredTransactions.isEmpty {
                emptyStateView
            } else {
                transactionList
            }
        }
        .navigationTitle("Transactions")
        .searchable(text: $searchText, prompt: "Search transactions")
        .sheet(isPresented: $showAddManual, onDismiss: { Task { await loadTransactions() } }) {
            AddTransactionView()
        }
        .sheet(isPresented: $showScanReceipt, onDismiss: { Task { await loadTransactions() } }) {
            ScanReceiptView()
        }
        .task {
            await loadTransactions()
        }
    }

    // Subviews

    private var filterBar: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(TransactionFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var transactionList: some View {
        List {
            // Filter picker
            Section {
                filterBar
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            // Total spend for current filter
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(totalLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(totalSpend, format: .currency(code: "USD"))
                            .font(.title.bold())
                    }
                    Spacer()
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.tint)
                }
                .padding(.vertical, 4)
            }

            ForEach(groupedTransactions, id: \.0) { label, dayTransactions in
                Section(label) {
                    ForEach(dayTransactions) { transaction in
                        TransactionRow(transaction: transaction)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await delete(transaction) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await loadTransactions()
        }
    }

    private var totalLabel: String {
        switch selectedFilter {
        case .day: return "Spent Today"
        case .month: return "Spent This Month"
        case .year: return "Spent This Year"
        case .all: return "Total Spent"
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            // Show filter bar even when empty
            filterBar

            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(filteredTransactions.isEmpty && !transactions.isEmpty ? "No transactions for this period" : "No Transactions Yet")
                .font(.title3.bold())
            Text(filteredTransactions.isEmpty && !transactions.isEmpty ?
                 "Try selecting a different time period." :
                 "Scan a receipt or add one manually to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if transactions.isEmpty {
                HStack(spacing: 12) {
                    Button { showScanReceipt = true } label: {
                        Label("Scan", systemImage: "camera")
                    }
                    .buttonStyle(.borderedProminent)
                    Button { showAddManual = true } label: {
                        Label("Manual", systemImage: "pencil")
                    }
                    .buttonStyle(.bordered)
                }
            }
            Spacer()
        }
    }

    // MARK: - Actions

    private func loadTransactions() async {
        isLoading = true
        do {
            transactions = try await TransactionService.fetch()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func delete(_ transaction: Transaction) async {
        do {
            try await TransactionService.delete(transaction)
            transactions.removeAll { $0.id == transaction.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(width: 44, height: 44)
                Text(transaction.category.emoji)
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.merchant)
                    .font(.body)
                    .fontWeight(.medium)
                Text(transaction.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.amount, format: .currency(code: "USD"))
                    .font(.body.weight(.semibold))
                Text(transaction.date, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
