import SwiftUI

// MARK: - RPM Calculation Utilities

struct RPMCalculations {
    
    // Calculate percentage difference from target RPM speeds
    static func calculatePercentageDifference(rpm: Double) -> Double? {
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
    
    // Calculate percentage difference from the closest target speed (for graph)
    // Always returns a value, even when outside the ±10% range
    static func calculatePercentageDifferenceForGraph(rpm: Double) -> Double? {
        let absRpm = abs(rpm)
        
        // Return nil if RPM is essentially zero
        guard absRpm > RPMTesterConfig.minimumDetectableRPM else { return nil }
        
        // Find the closest target speed
        guard let closestTargetSpeed = getClosestTargetSpeed(rpm: absRpm) else {
            return nil
        }
        
        // Return percentage difference from closest target
        return (absRpm - closestTargetSpeed) / closestTargetSpeed * 100
    }
    
    // Get color based on accuracy to target RPM
    static func getAccuracyColor(rpm: Double, motionManager: MotionManager) -> Color {
        let absRpm = abs(rpm)
        
        // Find the closest target speed
        guard let closestTargetSpeed = getClosestTargetSpeed(rpm: absRpm) else {
            return Color.clear
        }
        
        // Calculate percentage difference from closest target
        let percentageDiff = abs(absRpm - closestTargetSpeed) / closestTargetSpeed * 100
        
        if percentageDiff <= RPMTesterConfig.perfectAccuracyPercentage {
            // Check if all values in buffer are within perfect accuracy (stabilized)
            if isStabilizedAtTarget(rpm: absRpm, targetSpeed: closestTargetSpeed, motionManager: motionManager) {
                // Stabilized green - brightest possible
                return Color(
                    red: 0.0,
                    green: RPMTesterConfig.maxGreenLevelStabilized,
                    blue: 0.0,
                    opacity: RPMTesterConfig.stabilizedBackgroundOpacity
                )
            } else {
                // Max green - standard brightness
                return Color(
                    red: 0.0,
                    green: RPMTesterConfig.maxGreenLevelUnstabalised,
                    blue: 0.0,
                    opacity: RPMTesterConfig.backgroundOpacity
                )
            }
        } else if percentageDiff < RPMTesterConfig.maxPercentageDifference {
            // Smooth blend from green (at perfectAccuracyPercentage) to red (at maxPercentageDifference)
            let blendRange = RPMTesterConfig.maxPercentageDifference - RPMTesterConfig.perfectAccuracyPercentage // perfectAccuracyPercentage to maxPercentageDifference range
            let blendPosition = (percentageDiff - RPMTesterConfig.perfectAccuracyPercentage) / blendRange // 0.0 at perfectAccuracyPercentage, 1.0 at maxPercentageDifference
            
            // Direct blend: green fades out as red fades in
            let greenRatio = (1.0 - blendPosition) * RPMTesterConfig.maxGreenLevelUnstabalised // maxGreenLevelUnstabalised at 1%, 0.0 at 10%
            let redRatio = blendPosition // 0.0 at perfectAccuracyPercentage, 1.0 at maxPercentageDifference (red ratio is always max, as there's no stabalised red)
            
            // Create blended color with consistent opacity
            return Color(
                red: redRatio,
                green: greenRatio,
                blue: 0.0,
                opacity: RPMTesterConfig.backgroundOpacity
            )
        } else {
            // Maximum red when outside maxPercentageDifference
            return Color(
                red: 1.0,
                green: 0.0,
                blue: 0.0,
                opacity: RPMTesterConfig.backgroundOpacity
            )
        }
    }
    
    // Find the closest target speed for a given RPM
    static func getClosestTargetSpeed(rpm: Double) -> Double? {
        let absRpm = abs(rpm)
        
        var closestDistance = Double.infinity
        var closestTargetSpeed: Double = 0
        
        for targetSpeed in RPMTesterConfig.targetSpeeds {
            let distance = abs(absRpm - targetSpeed)
            if distance < closestDistance {
                closestDistance = distance
                closestTargetSpeed = targetSpeed
            }
        }
        
        return closestTargetSpeed > 0 ? closestTargetSpeed : nil
    }
    
    // Check if RPM is stabilized at target (finds closest target automatically)
    static func isStabilized(rpm: Double, motionManager: MotionManager) -> Bool {
        let absRpm = abs(rpm)
        
        // Find the closest target speed
        guard let closestTargetSpeed = getClosestTargetSpeed(rpm: absRpm) else {
            return false
        }
        
        // Check if stabilized at this target
        return isStabilizedAtTarget(rpm: absRpm, targetSpeed: closestTargetSpeed, motionManager: motionManager)
    }
    
    // Check if all values in the smoothing buffer are within perfect accuracy range
    static func isStabilizedAtTarget(rpm: Double, targetSpeed: Double, motionManager: MotionManager) -> Bool {
        // Need full buffer for stabilization check
        guard motionManager.rotationHistory.count >= RPMTesterConfig.rpmSmoothingHistorySize else {
            return false
        }
        
        // Check if all values in buffer are within 1% of the target
        let perfectThreshold = targetSpeed * (RPMTesterConfig.perfectAccuracyPercentage * 2.0 / 100.0) // FYI: We multiply the perfectAccuracyPercentage by 2 so that it is within perfectAccuracyPercentage _either side_ of the target 
        let allInRange = motionManager.rotationHistory.allSatisfy { value in
            abs(value - targetSpeed) <= perfectThreshold
        }
        
        return allInRange
    }
}
