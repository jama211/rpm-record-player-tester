//
//  RPMMeasurementView.swift
//  RPM Record Player Tester
//
//  Created by Jamie Williamson on 11/9/2025.
//

import SwiftUI
import CoreMotion

struct RPMMeasurementView: View {
    @Binding var showingMeasurement: Bool
    @StateObject private var motionManager = MotionManager()
    @State private var initialRotation: Double = 0
    @State private var hasSetInitialRotation = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                // Record visualization
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .background(
                        Circle()
                            .fill(getAccuracyColor(rpm: motionManager.rpm))
                    )
                    .frame(width: min(geometry.size.width, geometry.size.height) * 0.7)
                
                // Center dot
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                
                // RPM Display - rotation locked to initial orientation
                VStack(spacing: 10) {
                    Text(String(format: "%05.2f", min(abs(motionManager.rpm), 99.99)))
                        .font(.system(size: 72, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text("RPM")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Percentage difference from target speeds
                    if let percentageDiff = calculatePercentageDifference(rpm: motionManager.rpm) {
                        Text(String(format: "%+.2f%%", percentageDiff))
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .rotationEffect(.degrees(-motionManager.totalRotation + initialRotation))
                .onReceive(motionManager.$totalRotation) { rotation in
                    if !hasSetInitialRotation {
                        initialRotation = rotation
                        hasSetInitialRotation = true
                    }
                }
                
                // Back button
                VStack {
                    HStack {
                        Button(action: {
                            motionManager.stopUpdates()
                            showingMeasurement = false
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 20)
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            motionManager.startUpdates()
        }
        .onDisappear {
            motionManager.stopUpdates()
        }
    }
    
    // Calculate percentage difference from target RPM speeds
    private func calculatePercentageDifference(rpm: Double) -> Double? {
        let absRpm = abs(rpm)
        
        for targetSpeed in RPMTesterConfig.targetSpeeds {
            let percentageDiff = abs(absRpm - targetSpeed) / targetSpeed * 100
            
            // Check if within configured percentage limit of this target speed
            if percentageDiff < RPMTesterConfig.maxPercentageDifference {
                // Return the actual signed percentage difference
                return (absRpm - targetSpeed) / targetSpeed * 100
            }
        }
        
        return nil // Not within percentage limit of any target speed
    }
    
    // Get color based on accuracy to target RPM
    private func getAccuracyColor(rpm: Double) -> Color {
        let absRpm = abs(rpm)
        
        // Find the closest target speed
        var closestDistance: Double = Double.infinity
        for targetSpeed in RPMTesterConfig.targetSpeeds {
            let distance = abs(absRpm - targetSpeed)
            if distance < closestDistance {
                closestDistance = distance
            }
        }
        
        // Only show color if within good accuracy threshold
        if closestDistance < RPMTesterConfig.goodAccuracyThreshold {
            // Maximum green when within perfect accuracy threshold
            if closestDistance <= RPMTesterConfig.perfectAccuracyThreshold {
                return RPMTesterConfig.maxGreenColor
            } else {
                // Fade from max green at perfect threshold to transparent at good threshold
                let fadeRange = RPMTesterConfig.goodAccuracyThreshold - RPMTesterConfig.perfectAccuracyThreshold
                let fadePosition = (RPMTesterConfig.goodAccuracyThreshold - closestDistance) / fadeRange // 0.0 to 1.0
                return Color.green.opacity(RPMTesterConfig.maxGreenOpacity * fadePosition)
            }
        }
        
        return Color.clear
    }
}

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private var timer: Timer?
    private var lastUpdateTime: TimeInterval = 0
    private var rotationHistory: [Double] = []
    private let historySize = 10 // Keep last 10 readings for smoothing
    
    @Published var rpm: Double = 0.0
    @Published var totalRotation: Double = 0.0
    
    func startUpdates() {
        guard motionManager.isGyroAvailable else {
            print("Gyroscope not available")
            return
        }
        
        motionManager.gyroUpdateInterval = 0.1 // 10 Hz
        lastUpdateTime = Date().timeIntervalSince1970
        
        motionManager.startGyroUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self,
                  let gyroData = data else { return }
            
            let currentTime = Date().timeIntervalSince1970
            let deltaTime = currentTime - self.lastUpdateTime
            
            if deltaTime > 0 {
                // Z-axis rotation rate (around vertical axis)
                let rotationRate = gyroData.rotationRate.z
                
                // Convert radians per second to RPM
                let currentRPM = abs(rotationRate) * 60 / (2 * .pi)
                
                // Add to history for smoothing
                self.rotationHistory.append(currentRPM)
                if self.rotationHistory.count > self.historySize {
                    self.rotationHistory.removeFirst()
                }
                
                // Calculate smoothed RPM
                let smoothedRPM = self.rotationHistory.reduce(0, +) / Double(self.rotationHistory.count)
                
                DispatchQueue.main.async {
                    self.rpm = smoothedRPM
                    // Track total rotation for counter-rotation of text
                    self.totalRotation += rotationRate * deltaTime * 180 / .pi
                }
                
                self.lastUpdateTime = currentTime
            }
        }
    }
    
    func stopUpdates() {
        motionManager.stopGyroUpdates()
        timer?.invalidate()
        timer = nil
        rotationHistory.removeAll()
        rpm = 0.0
        totalRotation = 0.0
    }
}

#Preview {
    RPMMeasurementView(showingMeasurement: .constant(true))
}
