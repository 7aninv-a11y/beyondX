import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer().frame(height: 70)
                
                // 1. Fully Centered Header Lockup
                VStack(spacing: 6) {
                    HStack(alignment: .center, spacing: 8) {
                        Text("Beyond")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(Color(hex: "161616"))
                        
                        Image("Beyond X Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 85, height: 85)
                            .offset(y: 2)
                    }
                    
                    Text("Your Mind, No Limits.")
                        .font(.custom("Arial-BoldMT", size: 20))
                        .foregroundColor(Color(hex: "625F5F"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer().frame(height: 50)
                
                // 2. Robot Mascot Image
                Image("Robot Waving")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 270, height: 250)
                
                Spacer()
                
                // 3. Primary CTA Button
                NavigationLink(destination: JourneyView()) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 15, weight: .bold))
                        Text("Let’s Get Creative!")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(width: 240, height: 50)
                    .background(Color("AccentOrange"), in: Capsule())
                }
                .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("AppBackground").ignoresSafeArea())
        }
    }
}
