import SwiftUI

// MARK: - Configuration Constants
struct RPMTesterConfig {
    // Target RPM speeds for record players
    static let targetSpeeds: [Double] = [33.33, 45.0, 78.0]
    
    // Percentage difference limits
    static let maxPercentageDifference: Double = 10.0
    
    // Accuracy color thresholds (in percentage from target)
    static let perfectAccuracyPercentage: Double = 1.0   // Within ±1% shows max green
    static let goodAccuracyPercentage: Double = 5.0      // Within ±5% shows fading green (green-red transition point)
    
    // Visual styling
    static let backgroundOpacity: Double = 0.7          // Standard background opacity for all colors
    static let stabilizedBackgroundOpacity: Double = 0.9 // Brighter opacity when stabilized
    
    // Motion detection settings
    static let motionUpdateFrequency: Double = 120.0    // Hz - updates per second (higher = smoother counter-rotation)
    static let rpmSmoothingHistorySize: Int = 120       // Number of readings to average (120 readings = 1 second at 120Hz)
    static let minimumDetectableRPM: Double = 0.02      // Below this RPM, display shows 0.00 (even completely stationary, the gyroscope will return some noise)
    
}

struct ContentView: View {
    @State private var showingMeasurement = false
    
    var body: some View {
        if showingMeasurement {
            RPMMeasurementView(showingMeasurement: $showingMeasurement)
        } else {
            InstructionView(showingMeasurement: $showingMeasurement)
        }
    }
}

#Preview {
    ContentView()
}
