import SwiftUI

struct RPMDisplayComponent: View {
    let rpm: Double
    let totalRotation: Double
    let initialRotation: Double
    let motionManager: MotionManager
    
    // Get the processed RPM value (same as what's displayed)
    private var displayRPM: Double {
        return rpm < RPMTesterConfig.minimumDetectableRPM ? 0.0 : rpm
    }
    
    // Always return text to maintain consistent layout
    private var percentageText: String {
        if let percentageDiff = RPMCalculations.calculatePercentageDifference(rpm: displayRPM) {
            return String(format: "%+.2f%%", percentageDiff)
        } else {
            return " " // Single space to maintain layout height
        }
    }
    
    // Check if stabilized
    private var isStabilized: Bool {
        return RPMCalculations.isStabilized(rpm: displayRPM, motionManager: motionManager)
    }
    
    // Line width for the circle stroke
    private var circleLineWidth: CGFloat {
        return isStabilized ? 4 : 2
    }
    
    // Circle size (grows outward when stabilized)
    private var circleSize: CGFloat {
        // Base size + extra 2px when stabilized (to compensate for thicker stroke growing inward)
        return 280 + (isStabilized ? 2 : 0)
    }
    
    var body: some View {
        ZStack {
            // Record visualization
            Circle()
                .stroke(Color.white, lineWidth: circleLineWidth)
                .background(
                    Circle()
                        .fill(RPMCalculations.getAccuracyColor(rpm: displayRPM, motionManager: motionManager))
                )
                .frame(width: circleSize, height: circleSize)
            
            // Center dot
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
            
            // RPM Display - rotation locked to initial orientation
            VStack(spacing: 10) {
                Text(String(format: "%05.2f", min(abs(displayRPM), 99.99)))
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("RPM")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.8))
                
                // Percentage difference from target speeds (always reserve space)
                Text(percentageText)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
            .offset(y: 15) // Move down to center the decimal point in the center of the circle 
            .rotationEffect(.degrees(RPMTesterConfig.testingModeEnabled ? 0 : -totalRotation + initialRotation))
        }
    }
}

#Preview {
    RPMDisplayComponent(
        rpm: 00.00,
        totalRotation: 0.0,
        initialRotation: 0.0,
        motionManager: MotionManager()
    )
    .background(Color.black)
}
