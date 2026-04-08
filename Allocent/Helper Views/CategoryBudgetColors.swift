import SwiftUI

/// Dashboard category colors: stable palette by sort order; bright red when over that category's limit.
enum CategoryBudgetColors {
    /// Default sequence for category rows and donut segments (matches prior donut fallbacks).
    static let palette: [Color] = [
        .blue,
        .orange,
        .purple,
        .green,
        .pink,
        .cyan,
        .mint,
        .indigo,
    ]

    static let overBudget = Color(red: 1.0, green: 0.2, blue: 0.2)

    static func displayColor(for summary: CategorySummary, paletteIndex: Int) -> Color {
        if summary.limit > 0, summary.spent > summary.limit {
            return overBudget
        }
        return palette[paletteIndex % palette.count]
    }
}
