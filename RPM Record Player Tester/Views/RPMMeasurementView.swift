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
                // Maximum green when within perfect accuracy percentage
                return RPMTesterConfig.maxGreenColor
            } else if percentageDiff < RPMTesterConfig.goodAccuracyPercentage {
                // Green gets stronger from nothing to strong as you approach perfect accuracy
                let fadeRange = RPMTesterConfig.goodAccuracyPercentage - RPMTesterConfig.perfectAccuracyPercentage
                let fadePosition = (RPMTesterConfig.goodAccuracyPercentage - percentageDiff) / fadeRange // 1.0 at perfect, 0.0 at good boundary
                return Color.green.opacity(RPMTesterConfig.maxGreenOpacity * fadePosition)
            } else {
                // Red fades based on distance to worst possible speed (midpoints between targets)
                let worstSpeeds = [0.0, 39.165, 61.5, 99.99] // 0, (33.33+45)/2, (45+78)/2, upper limit
                
                // Find distance to closest worst speed
                var closestWorstDistance = Double.infinity
                for worstSpeed in worstSpeeds {
                    let distance = abs(absRpm - worstSpeed)
                    if distance < closestWorstDistance {
                        closestWorstDistance = distance
                    }
                }
                
                // Calculate how far we are from the green-red transition boundary
                let greenRedBoundaryDistance = closestTargetSpeed * (RPMTesterConfig.goodAccuracyPercentage / 100.0)
                let distanceBeyondGreenZone = max(0, closestDistance - greenRedBoundaryDistance)
                
                // Calculate distance to worst speed
                let distanceToWorst = closestWorstDistance
                let maxPossibleDistance = distanceToWorst + greenRedBoundaryDistance
                
                if maxPossibleDistance > 0 {
                    // Red intensity: 0.0 at green-red boundary, 1.0 at worst speed
                    let redIntensity = distanceBeyondGreenZone / (distanceToWorst - greenRedBoundaryDistance + distanceBeyondGreenZone)
                    return Color.red.opacity(RPMTesterConfig.maxRedOpacity * min(1.0, redIntensity))
                } else {
                    return RPMTesterConfig.maxRedColor
                }
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
    
    @Published var rpm: Double = 0.0
    @Published var totalRotation: Double = 0.0
    
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
                self.rotationHistory.append(currentRPM)
                if self.rotationHistory.count > RPMTesterConfig.rpmSmoothingHistorySize {
                    self.rotationHistory.removeFirst()
                }
                
                // Calculate smoothed RPM with outlier rejection
                let smoothedRPM = self.calculateRobustAverage(from: self.rotationHistory)
                
                // Apply minimum detectable threshold - below this is sensor noise
                let finalRPM = smoothedRPM < RPMTesterConfig.minimumDetectableRPM ? 0.0 : smoothedRPM
                
                // Testing mode override
                self.rpm = RPMTesterConfig.testingMode ? RPMTesterConfig.testingModeRPM : finalRPM
                
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
        rotationHistory.removeAll()
        rpm = 0.0
        totalRotation = 0.0
    }
    
    // Calculate average while rejecting outliers to prevent spikes during acceleration
    private func calculateRobustAverage(from values: [Double]) -> Double {
        guard values.count >= 3 else {
            // Not enough data for outlier detection, use simple average
            return values.reduce(0.0, +) / Double(values.count)
        }
        
        // Sort values to find median and detect outliers
        let sortedValues = values.sorted()
        let median = sortedValues[sortedValues.count / 2]
        
        // Calculate median absolute deviation (MAD) for outlier detection
        let deviations = sortedValues.map { abs($0 - median) }
        let mad = deviations.sorted()[deviations.count / 2]
        
        // Filter out outliers (values more than 2 MADs from median)
        let threshold = max(mad * 2.0, 0.5) // Minimum threshold of 0.5 RPM
        let filteredValues = sortedValues.filter { abs($0 - median) <= threshold }
        
        // Return average of filtered values
        return filteredValues.isEmpty ? 0.0 : filteredValues.reduce(0.0, +) / Double(filteredValues.count)
    }
}

#Preview {
    RPMMeasurementView(showingMeasurement: .constant(true))
}
