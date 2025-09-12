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
    static let maxGreenOpacity: Double = 0.7            // Dark, desaturated green
    static let maxGreenColor = Color.green.opacity(maxGreenOpacity)
    static let maxRedOpacity: Double = 0.7              // Dark, desaturated red
    static let maxRedColor = Color.red.opacity(maxRedOpacity)
    
    // Motion detection settings
    static let motionUpdateFrequency: Double = 120.0    // Hz - updates per second (higher = smoother counter-rotation)
    static let rpmSmoothingHistorySize: Int = 20        // Number of readings to average (more = smoother RPM)
    static let minimumDetectableRPM: Double = 0.02      // Below this RPM, display shows 0.00 (even completely stationary, the gyroscope will return some noise)
    
    // Testing mode
    static let testingMode: Bool = false                 // When true, override with test RPM value
    static let testingModeRPM: Double = 33.33           // RPM value to use in testing mode
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
