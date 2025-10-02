import SwiftUI

struct WowFlutterGraphComponent: View {
    
    // Graph configuration constants
    private let graphHeight: CGFloat = 200 // Height of the graph area
    private let graphRangePercentage: Double = 10.0 // Graph range: +/- this percentage
    private let maxDataPoints: Int = 100 // Number of data points to display
    private let jumpThreshold: Double = 15.0 // Percentage jump threshold to detect target speed changes

    // Graph data
    let percentageHistory: [Double] // Array of percentage differences over time
    
    // Find the index of the most recent large jump (target speed change)
    private var lastJumpIndex: Int? {
        guard percentageHistory.count > 1 else { return nil }
        
        // Find the most recent large jump (indicating target speed change)
        for i in (1..<percentageHistory.count).reversed() {
            let diff = abs(percentageHistory[i] - percentageHistory[i - 1])
            if diff > jumpThreshold {
                return i
            }
        }
        
        return nil
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Graph title
            Text("Wow & Flutter")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            // Graph area
            ZStack {
                // Background
                Rectangle()
                    .fill(Color.black)
                    .frame(height: graphHeight)
                
                // Grid lines
                VStack(spacing: 0) {
                    // +10% line
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 0.5)
                    
                    Spacer()
                    
                    // 0% line (center)
                    Rectangle()
                        .fill(Color.white.opacity(0.4))
                        .frame(height: 1)
                    
                    Spacer()
                    
                    // -10% line
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 0.5)
                }
                .frame(height: graphHeight)
                
                // Percentage labels
                HStack {
                    VStack {
                        Text("+\(Int(graphRangePercentage))%")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.4))
                        
                        Spacer()
                        
                        Text("0%")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text("-\(Int(graphRangePercentage))%")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .frame(height: graphHeight)
                    
                    Spacer()
                }
                .padding(.leading, 4)
                
                // Graph line - draw old data (before jump) with lower opacity
                if !percentageHistory.isEmpty {
                    let jumpIdx = lastJumpIndex
                    
                    // Draw old data (before jump) if there is one
                    if let jumpIdx = jumpIdx, jumpIdx > 0 {
                        GraphLineView(
                            data: Array(percentageHistory[..<jumpIdx]),
                            startIndex: 0,
                            maxDataPoints: maxDataPoints,
                            graphRangePercentage: graphRangePercentage
                        )
                        .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                        .frame(height: graphHeight)
                        .padding(.leading, 30)
                        .padding(.trailing, 8)
                    }
                    
                    // Draw current data (after jump, or all data if no jump)
                    let currentDataStart = jumpIdx ?? 0
                    if currentDataStart < percentageHistory.count {
                        GraphLineView(
                            data: Array(percentageHistory[currentDataStart...]),
                            startIndex: currentDataStart,
                            maxDataPoints: maxDataPoints,
                            graphRangePercentage: graphRangePercentage
                        )
                        .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                        .frame(height: graphHeight)
                        .padding(.leading, 30)
                        .padding(.trailing, 8)
                    }
                }
            }
            .frame(height: graphHeight)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
    }
}

// Custom shape for drawing the graph line
struct GraphLineView: Shape {
    let data: [Double]
    let startIndex: Int
    let maxDataPoints: Int
    let graphRangePercentage: Double
    
    func path(in rect: CGRect) -> Path {
        guard !data.isEmpty else { return Path() }
        
        var path = Path()
        let width = rect.width
        let height = rect.height
        let centerY = height / 2
        
        // Always calculate step based on maxDataPoints to maintain consistent scale
        let stepX = width / CGFloat(max(maxDataPoints - 1, 1))
        
        // Draw the line segment for this data at its actual buffer position
        for (index, percentage) in data.enumerated() {
            let actualIndex = startIndex + index
            // Only draw if within the maxDataPoints range
            if actualIndex < maxDataPoints {
                let x = CGFloat(actualIndex) * stepX
                let y = centerY - (CGFloat(percentage) / graphRangePercentage) * (height / 2)
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        
        return path
    }
}

#Preview {
    WowFlutterGraphComponent(
        percentageHistory: [-2.1, -1.5, -0.8, 0.2, 1.1, 0.5, -0.3, 0.8, 1.2, -0.5]
    )
    .background(Color.black)
}
