import SwiftUI

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
                
                // RPM Display Component
                RPMDisplayComponent(
                    rpm: motionManager.rpm,
                    totalRotation: motionManager.totalRotation,
                    initialRotation: initialRotation,
                    motionManager: motionManager
                )
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

#Preview {
    RPMMeasurementView(showingMeasurement: .constant(true))
}
