import SwiftUI
import Charts

struct BudgetDonutChartView: View {
    let summaries: [CategorySummary]
    let totalSpent: Double

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    private var slices: [(summary: CategorySummary, amount: Double, color: Color)] {
        let positive = summaries
            .filter { $0.spent > 0 }
            .sorted { $0.name < $1.name }
        let indexed = summaries.sorted { $0.name < $1.name }
        if totalSpent > 0 {
            return positive.map { s in
                let idx = indexed.firstIndex(where: { $0.id == s.id }) ?? 0
                return (s, s.spent, resolvedColor(for: s, indexInAll: idx))
            }
        }
        return []
    }

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
                    .stroke(Color("OliveGreen").opacity(0.28), lineWidth: 28)
                    .frame(width: 220, height: 220)
            } else {
                Chart(slices, id: \.summary.id) { item in
                    SectorMark(
                        angle: .value("Spent", item.amount),
                        innerRadius: .ratio(0.65),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                }
                .chartLegend(.hidden)
                .frame(width: 250, height: 250)
            }

            VStack(spacing: 4) {
                Text("We spent")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(formatCurrencyWhole(totalSpent))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
                Text(monthLabel)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("We spent \(formatCurrencyWhole(totalSpent)) in \(monthLabel)")
        }
    }

    private func formatCurrencyWhole(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale.current
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "$0"
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
