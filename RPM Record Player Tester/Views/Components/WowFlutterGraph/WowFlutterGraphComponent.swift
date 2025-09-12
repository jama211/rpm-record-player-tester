import SwiftUI

struct WowFlutterGraphComponent: View {
    let percentageHistory: [Double] // Array of percentage differences over time
    let maxDataPoints: Int = 100 // Number of data points to display
    
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
                    .frame(height: 80)
                
                // Grid lines
                VStack(spacing: 0) {
                    // +5% line
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 0.5)
                    
                    Spacer()
                    
                    // 0% line (center)
                    Rectangle()
                        .fill(Color.white.opacity(0.4))
                        .frame(height: 1)
                    
                    Spacer()
                    
                    // -5% line
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 0.5)
                }
                .frame(height: 80)
                
                // Percentage labels
                HStack {
                    VStack {
                        Text("+5%")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.4))
                        
                        Spacer()
                        
                        Text("0%")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text("-5%")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .frame(height: 80)
                    
                    Spacer()
                }
                .padding(.leading, 4)
                
                // Graph line
                if !percentageHistory.isEmpty {
                    GraphLineView(data: percentageHistory, maxDataPoints: maxDataPoints)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                        .frame(height: 80)
                        .padding(.leading, 30) // Make room for labels
                        .padding(.trailing, 8)
                }
            }
            .frame(height: 80)
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
    let maxDataPoints: Int
    
    func path(in rect: CGRect) -> Path {
        guard data.count > 1 else { return Path() }
        
        var path = Path()
        let width = rect.width
        let height = rect.height
        let centerY = height / 2
        
        // Use the most recent data points (up to maxDataPoints)
        let recentData = Array(data.suffix(maxDataPoints))
        let stepX = width / CGFloat(max(recentData.count - 1, 1))
        
        // Start from the first point
        let firstY = centerY - (CGFloat(recentData[0]) / 5.0) * (height / 2) // Scale -5% to +5% across height
        path.move(to: CGPoint(x: 0, y: firstY))
        
        // Draw lines to subsequent points
        for (index, percentage) in recentData.enumerated() {
            if index > 0 {
                let x = CGFloat(index) * stepX
                let y = centerY - (CGFloat(percentage) / 5.0) * (height / 2) // Scale -5% to +5% across height
                path.addLine(to: CGPoint(x: x, y: y))
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
