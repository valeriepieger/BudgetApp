import SwiftUI

struct SemiCircleProgressView: View {
    var safeToSpend: Double
    var totalBudget: Double
    
    private var progress: Double {
        guard totalBudget > 0 else { return 0 }
        return min(max(safeToSpend / totalBudget, 0), 1)
    }
    
    var body: some View {
        ZStack {
            SemiCircleShape()
                .stroke(Color.gray.opacity(0.2), lineWidth: 22)
            
            SemiCircleShape()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color("OliveGreen"),
                            Color.yellow,
                            Color.pink
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 22, lineCap: .round)
                )
                .animation(.spring(response: 0.6, dampingFraction: 0.9), value: progress)
            
            VStack(spacing: 4) {
                Text("$\(safeToSpend, specifier: "%.0f")")
                    .font(.system(size: 40, weight: .bold))
                Text("safe-to-spend")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("out of $\(totalBudget, specifier: "%.0f") budget")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 24)
        }
    }
}

struct SemiCircleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        return path
    }
}

