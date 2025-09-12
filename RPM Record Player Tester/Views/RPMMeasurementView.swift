import SwiftUI
import CoreMotion

struct RPMMeasurementView: View {
    @Binding var showingMeasurement: Bool
    @StateObject private var motionManager = MotionManager()
    @State private var initialRotation: Double = 0
    @State private var hasSetInitialRotation = false
    
    // Get the processed RPM value (same as what's displayed)
    private var displayRPM: Double {
        return motionManager.rpm < RPMTesterConfig.minimumDetectableRPM ? 0.0 : motionManager.rpm
    }
    
    // Always return text to maintain consistent layout
    private var percentageText: String {
        if let percentageDiff = calculatePercentageDifference(rpm: displayRPM) {
            return String(format: "%+.2f%%", percentageDiff)
        } else {
            return " " // Single space to maintain layout height
        }
    }
    
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
                            .fill(getAccuracyColor(rpm: displayRPM))
                    )
                    .frame(width: min(geometry.size.width, geometry.size.height) * 0.7)
                
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
                .offset(y: 15) // Move down to match original position
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
        var closestTargetSpeed: Double = 0
        
        for targetSpeed in RPMTesterConfig.targetSpeeds {
            let distance = abs(absRpm - targetSpeed)
            if distance < closestDistance {
                closestDistance = distance
                closestTargetSpeed = targetSpeed
            }
        }
        
        // Calculate percentage difference from closest target
        if closestTargetSpeed > 0 {
            let percentageDiff = abs(absRpm - closestTargetSpeed) / closestTargetSpeed * 100
            
            if percentageDiff <= RPMTesterConfig.perfectAccuracyPercentage {
                // Check if all values in buffer are within perfect accuracy (stabilized)
                if isStabilizedAtTarget(rpm: absRpm, targetSpeed: closestTargetSpeed) {
                    // Stabilized green - brightest possible
                    return Color(
                        red: 0.0,
                        green: 1.0,
                        blue: 0.0,
                        opacity: RPMTesterConfig.stabilizedBackgroundOpacity
                    )
                } else {
                    // Max green - standard brightness
                    return Color(
                        red: 0.0,
                        green: 1.0,
                        blue: 0.0,
                        opacity: RPMTesterConfig.backgroundOpacity
                    )
                }
            } else if percentageDiff < RPMTesterConfig.maxPercentageDifference {
                // Smooth blend from green (at 1%) to red (at 10%) - no 5% boundary
                let blendRange = RPMTesterConfig.maxPercentageDifference - RPMTesterConfig.perfectAccuracyPercentage // 9% range (1% to 10%)
                let blendPosition = (percentageDiff - RPMTesterConfig.perfectAccuracyPercentage) / blendRange // 0.0 at 1%, 1.0 at 10%
                
                // Direct blend: green fades out as red fades in
                let greenRatio = (1.0 - blendPosition) // 1.0 at 1%, 0.0 at 10%
                let redRatio = blendPosition // 0.0 at 1%, 1.0 at 10%
                
                
                // Create blended color with consistent opacity
                return Color(
                    red: redRatio,
                    green: greenRatio,
                    blue: 0.0,
                    opacity: RPMTesterConfig.backgroundOpacity
                )
            } else {
                // Maximum red when outside 10%
                return Color(
                    red: 1.0,
                    green: 0.0,
                    blue: 0.0,
                    opacity: RPMTesterConfig.backgroundOpacity
                )
            }
        }
        
        return Color.clear
    }
    
    // Check if all values in the smoothing buffer are within perfect accuracy range
    private func isStabilizedAtTarget(rpm: Double, targetSpeed: Double) -> Bool {
        // Need full buffer for stabilization check
        guard motionManager.rotationHistory.count >= RPMTesterConfig.rpmSmoothingHistorySize else {
            return false
        }
        
        // Check if all values in buffer are within 1% of the target
        let perfectThreshold = targetSpeed * (RPMTesterConfig.perfectAccuracyPercentage / 100.0)
        let allInRange = motionManager.rotationHistory.allSatisfy { value in
            abs(value - targetSpeed) <= perfectThreshold
        }
        
        
        return allInRange
    }
}

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private var timer: Timer?
    private var lastUpdateTime: TimeInterval = 0
    private var _rotationHistory: [Double] = []
    
    @Published var rpm: Double = 0.0
    @Published var totalRotation: Double = 0.0
    
    // Provide read-only access to rotation history for stabilization check
    var rotationHistory: [Double] {
        return self._rotationHistory
    }
    
    
    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / RPMTesterConfig.motionUpdateFrequency
        lastUpdateTime = Date().timeIntervalSince1970
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
            guard let self = self,
                  let deviceMotion = motion else { return }
            
            let currentTime = Date().timeIntervalSince1970
            let deltaTime = currentTime - self.lastUpdateTime
            
            if deltaTime > 0 {
                // Z-axis rotation rate (around vertical axis) for RPM calculation
                let rotationRate = deviceMotion.rotationRate.z
                
                // Convert raw rotation rate to RPM (60 seconds in a minute, 2π radians in a circle)
                let currentRPM = abs(rotationRate) * 60.0 / (2.0 * Double.pi)
                
                // Add to history for smoothing
                self._rotationHistory.append(currentRPM)
                if self._rotationHistory.count > RPMTesterConfig.rpmSmoothingHistorySize {
                    self._rotationHistory.removeFirst()
                }
                
                // Calculate smoothed RPM
                let smoothedRPM = self._rotationHistory.reduce(0.0, +) / Double(self._rotationHistory.count)
                
                // Apply minimum detectable threshold - below this is sensor noise
                let finalRPM = smoothedRPM < RPMTesterConfig.minimumDetectableRPM ? 0.0 : smoothedRPM
                
                self.rpm = finalRPM
                
                // Use rotation rate integration for counter-rotation (more stable under fast movement)
                // Integrate the Z-axis rotation rate over time
                // rotationRate (rad/s) * deltaTime (s) * (180/π) converts radians to degrees for SwiftUI
                self.totalRotation -= rotationRate * deltaTime * (180.0 / Double.pi)

                self.lastUpdateTime = currentTime
            }
        }
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
        timer?.invalidate()
        timer = nil
        _rotationHistory.removeAll()
        rpm = 0.0
        totalRotation = 0.0
    }
}

#Preview {
    RPMMeasurementView(showingMeasurement: .constant(true))
}
