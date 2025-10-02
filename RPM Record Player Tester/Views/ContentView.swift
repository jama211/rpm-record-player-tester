import SwiftUI

// MARK: - Configuration Constants
struct RPMTesterConfig {
    // Target RPM speeds for record players
    static let targetSpeeds: [Double] = [33.33, 45.0, 78.0]
    
    // Percentage difference limits
    static let perfectAccuracyPercentage: Double = 1.0      // Within ±1% shows max green
    static let maxPercentageDifference: Double = 10.0       // Must be larger than perfectAccuracyPercentage
    
    // Visual styling
    static let backgroundOpacity: Double = 0.7              // Standard background opacity for all colors
    static let stabilizedBackgroundOpacity: Double = 0.9    // Brighter opacity when stabilized
    static let maxGreenLevelUnstabalised: Double = 0.8      // Less green otherwise
    static let maxGreenLevelStabilized: Double = 0.9        // Greener when stabalised
    
    // Motion detection settings
    static let motionUpdateFrequency: Double = 120.0        // Hz - updates per second (higher = smoother counter-rotation)
    static let rpmSmoothingHistorySize: Int = 120           // Number of readings to average (120 readings = 1 second at 120Hz)
    static let minimumDetectableRPM: Double = 0.02          // Below this RPM, display shows 0.00 (to hide stationary noise)
    
    // Testing mode settings
    #if DEBUG
    static var testingModeVisible: Bool = true              // Show testing mode toggle in UI (Debug only)
    static var testingModeEnabled: Bool = true              // Enable fake data for testing (Debug only)
    #else
    static var testingModeVisible: Bool = false             // Hidden in Release builds
    static var testingModeEnabled: Bool = false             // Disabled in Release builds
    #endif

    // Testing mode variables, note: these are relevant when testing mode is enabled 
    static let testingModeStartRPM: Double = 28.0           // Starting RPM for test ramp
    static let testingModeEndRPM: Double = 78.0             // Ending RPM for test ramp
    static let testingModeRampRate: Double = 1.0            // RPM increase per second
    static let testingModeWowFrequency1: Double = 0.7       // Hz - slow speed variation frequency
    static let testingModeWowFrequency2: Double = 1.3       // Hz - slow speed variation frequency
    static let testingModeWowAmplitude1: Double = 0.005     // ±0.5% variation
    static let testingModeWowAmplitude2: Double = 0.007     // ±0.7% variation
    static let testingModeFlutterFrequency1: Double = 6.5   // Hz - fast variation frequency
    static let testingModeFlutterFrequency2: Double = 8.2   // Hz - fast variation frequency
    static let testingModeFlutterAmplitude1: Double = 0.005 // ±0.5% variation
    static let testingModeFlutterAmplitude2: Double = 0.003 // ±0.3% variation
    static let testingModeNoiseAmplitude: Double = 0.002    // ±0.2% random noise
    
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
