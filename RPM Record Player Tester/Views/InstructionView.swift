import SwiftUI

struct InstructionView: View {
    @Binding var showingMeasurement: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            (colorScheme == .dark ? Color.black : Color.clear)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                // App Title
                VStack(spacing: 10) {
                    Image(systemName: "record.circle")
                        .font(.system(size: 60))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    Text("RPM Record Player Tester")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                }
                .padding(.top, 80)
                .padding(.bottom, 50)
            
                // Instructions
                VStack(spacing: 20) {
                    VStack(spacing: 20) {
                        Text("Place your phone on the center of the turntable.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        Text("If there is a spike there, don't worry! Grab a cup from your cupboard, turn it upside down, then place the phone on the cup over the spike.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        Text("Keep the phone centered as much as possible.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        Text("When you're ready, press start!")
                            .multilineTextAlignment(.center)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
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
}

#Preview {
    InstructionView(showingMeasurement: .constant(false))
}
