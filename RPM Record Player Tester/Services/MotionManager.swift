import Foundation
import CoreMotion

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private var timer: Timer?
    private var lastUpdateTime: TimeInterval = 0
    private var _rotationHistory: [Double] = []
    
    // Testing mode variables
    private var testingModeStartTime: TimeInterval = 0
    private var testingModeCurrentRPM: Double = 0
    
    @Published var rpm: Double = 0.0
    @Published var totalRotation: Double = 0.0
    @Published var percentageHistory: [Double] = [] // For wow/flutter graph
    
    // Provide read-only access to rotation history for stabilization check
    var rotationHistory: [Double] {
        return self._rotationHistory
    }
    
    func startUpdates() {
        // Check if testing mode is enabled
        if RPMTesterConfig.testingModeEnabled {
            startTestingMode()
            return
        }
        
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
                
                self.processRPMData(currentRPM: currentRPM, deltaTime: deltaTime, rotationRate: rotationRate)
                
                self.lastUpdateTime = currentTime
            }
        }
    }
    
    private func startTestingMode() {
        testingModeStartTime = Date().timeIntervalSince1970
        testingModeCurrentRPM = RPMTesterConfig.testingModeStartRPM
        lastUpdateTime = testingModeStartTime
        
        // Create a timer to simulate motion updates
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / RPMTesterConfig.motionUpdateFrequency, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let currentTime = Date().timeIntervalSince1970
            let deltaTime = currentTime - self.lastUpdateTime
            let elapsedTime = currentTime - self.testingModeStartTime
            
            // Calculate current RPM based on ramp rate
            self.testingModeCurrentRPM = min(
                RPMTesterConfig.testingModeStartRPM + (elapsedTime * RPMTesterConfig.testingModeRampRate),
                RPMTesterConfig.testingModeEndRPM
            )
            
            // Add small random variation to simulate real-world wow/flutter (±0.5%)
            let variation = Double.random(in: -0.005...0.005)
            let simulatedRPM = self.testingModeCurrentRPM * (1.0 + variation)
            
            self.processRPMData(currentRPM: simulatedRPM, deltaTime: deltaTime, rotationRate: 0)
            
            self.lastUpdateTime = currentTime
        }
    }
    
    private func processRPMData(currentRPM: Double, deltaTime: Double, rotationRate: Double) {
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
        
        // Update percentage history for wow/flutter graph
        if let percentageDiff = RPMCalculations.calculatePercentageDifference(rpm: finalRPM) {
            self.percentageHistory.append(percentageDiff)
            // Keep only the last 100 data points for the graph
            if self.percentageHistory.count > 100 {
                self.percentageHistory.removeFirst()
            }
        }
        
        // Use rotation rate integration for counter-rotation (more stable under fast movement)
        // In testing mode, simulate rotation
        if RPMTesterConfig.testingModeEnabled {
            // Simulate smooth rotation based on current RPM
            let rotationPerSecond = (finalRPM / 60.0) * 360.0 // degrees per second
            self.totalRotation += rotationPerSecond * deltaTime
        } else {
            // Integrate the Z-axis rotation rate over time
            // rotationRate (rad/s) * deltaTime (s) * (180/π) converts radians to degrees for SwiftUI
            self.totalRotation -= rotationRate * deltaTime * (180.0 / Double.pi)
        }
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
        timer?.invalidate()
        timer = nil
        _rotationHistory.removeAll()
        rpm = 0.0
        totalRotation = 0.0
        percentageHistory.removeAll()
    }
}
