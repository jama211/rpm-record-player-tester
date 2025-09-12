//
//  ContentView.swift
//  RPM Record Player Tester
//
//  Created by Jamie Williamson on 11/9/2025.
//

import SwiftUI
import CoreMotion

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

struct InstructionView: View {
    @Binding var showingMeasurement: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            
            // App Title
            VStack(spacing: 10) {
                Image(systemName: "record.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.primary)
                
                Text("RPM Record Player Tester")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding(.top, 80)
            .padding(.bottom, 50)
            
            // Instructions
            VStack(spacing: 20) {
                VStack(spacing: 20) {
                    Text("Place your phone on the center of the turntable.")
                        .multilineTextAlignment(.center)
                    
                    Text("If there is a spike there, don't worry! Grab a cup from your cupboard, turn it upside down, then place the phone on the cup over the spike.")
                        .multilineTextAlignment(.center)
                    
                    Text("Keep the phone centered as much as possible.")
                        .multilineTextAlignment(.center)
                    
                    Text("When you're ready, press start!")
                        .multilineTextAlignment(.center)
                }
                .font(.body)
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // Start Button
            Button(action: {
                showingMeasurement = true
            }) {
                Text("Start")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }
}

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
    ContentView()
}
