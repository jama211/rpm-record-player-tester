//
//  ContentView.swift
//  RPM Record Player Tester
//
//  Created by Jamie Williamson on 11/9/2025.
//

import SwiftUI

// MARK: - Configuration Constants
struct RPMTesterConfig {
    // Target RPM speeds for record players
    static let targetSpeeds: [Double] = [33.33, 45.0, 78.0]
    
    // Percentage difference limits
    static let maxPercentageDifference: Double = 10.0
    
    // Accuracy color thresholds (in RPM)
    static let perfectAccuracyThreshold: Double = 0.05  // Within ±0.05 RPM shows max green
    static let goodAccuracyThreshold: Double = 0.1     // Within ±0.1 RPM shows fading green
    
    // Visual styling
    static let maxGreenOpacity: Double = 0.3            // Dark, desaturated green
    static let maxGreenColor = Color.green.opacity(maxGreenOpacity)
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