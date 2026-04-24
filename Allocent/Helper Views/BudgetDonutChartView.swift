import SwiftUI
import Charts

private struct DonutSlice: Identifiable {
    let id: String
    let value: Double
    let color: Color
}

struct BudgetDonutChartView: View {
    let summaries: [CategorySummary]
    let totalBudget: Double
    let totalSpent: Double
    let safeToSpend: Double

    private var asOfDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: Date())
    }

    /// Ring fills 100% of the circle: under budget = spent segments + remainder; over budget = spent only (normalized to full circle, capped).
    private var slices: [DonutSlice] {
        let sorted = summaries.sorted { $0.name < $1.name }
        let indexed = Array(sorted.enumerated())

        if totalBudget <= 0 {
            if totalSpent <= 0 { return [] }
            return spendingOnlySlices(indexed: indexed)
        }

        if totalSpent <= totalBudget {
            var result: [DonutSlice] = []
            for (idx, s) in indexed {
                guard s.spent > 0 else { continue }
                result.append(
                    DonutSlice(
                        id: s.id,
                        value: s.spent,
                        color: resolvedColor(for: s, indexInAll: idx)
                    )
                )
            }
            let remaining = max(totalBudget - totalSpent, 0)
            if remaining > 0.0001 {
                result.append(
                    DonutSlice(
                        id: "remaining",
                        value: remaining,
                        color: Color.gray.opacity(0.22)
                    )
                )
            }
            return result
        }

        // Over budget: cap ring at 100% — show category shares of total spent (full circle).
        return spendingOnlySlices(indexed: indexed)
    }

    private func spendingOnlySlices(
        indexed: [(offset: Int, element: CategorySummary)]
    ) -> [DonutSlice] {
        let withSpend = indexed.filter { $0.element.spent > 0 }
        guard !withSpend.isEmpty else { return [] }
        return withSpend.map { pair in
            let s = pair.element
            return DonutSlice(
                id: s.id,
                value: s.spent,
                color: resolvedColor(for: s, indexInAll: pair.offset)
            )
        }
    }

    /// Donut uses category hex when set; otherwise the standard fallback palette (not tied to row styling / over-budget red).
    private func resolvedColor(for summary: CategorySummary, indexInAll: Int) -> Color {
        if let hex = summary.colorHex, let c = Color(hex: hex) {
            return c
        }
        let fallbacks: [Color] = [.blue, .orange, .purple, .green, .pink, .cyan, .mint, .indigo]
        return fallbacks[indexInAll % fallbacks.count]
    }

    var body: some View {
        ZStack {
            if slices.isEmpty {
                Circle()
                    .stroke(Color("OliveGreen").opacity(0.28), lineWidth: 20)
                    .frame(width: 280, height: 280)
            } else {
                Chart(slices) { item in
                    SectorMark(
                        angle: .value("Budget", item.value),
                        innerRadius: .ratio(0.78),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.color)
                }
                .chartLegend(.hidden)
                .frame(width: 300, height: 300)
            }

            VStack(spacing: 4) {
                Text("Safe to spend")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(formatCurrencyTwoDecimals(safeToSpend))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.85)
                    .lineLimit(1)
                Text("as of \(asOfDateLabel)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Safe to spend \(formatCurrencyTwoDecimals(safeToSpend)) as of \(asOfDateLabel)")
        }
    }

    private func formatCurrencyTwoDecimals(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale.current
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

private extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 8 else { return nil }

        var value: UInt64 = 0
        guard Scanner(string: s).scanHexInt64(&value) else { return nil }

        let a, r, g, b: UInt64
        if s.count == 8 {
            a = (value & 0xFF00_0000) >> 24
            r = (value & 0x00FF_0000) >> 16
            g = (value & 0x0000_FF00) >> 8
            b = value & 0x0000_00FF
        } else {
            a = 255
            r = (value & 0xFF0000) >> 16
            g = (value & 0x00FF00) >> 8
            b = value & 0x0000FF
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
