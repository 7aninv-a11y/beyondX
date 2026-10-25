import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Spacer()
            
            // 1. Logo Section: "Beyond" text + your custom SVG X-Logo
            HStack(spacing: 6) {
                Text("Beyond")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(Color.nearBlack)
                
                Image("Beyond X Logo") // Matches your asset name
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
            }
            
            // 2. Tagline
            Text("Your Mind, No Limits.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("textSplashTagline")) // Using your exact extracted hex #625F5F
                .padding(.top, 4)
            
            Spacer()
            
            // 3. Robot Mascot Image
            Image("Robot Waving") // Matches your asset name
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 240)
            
            Spacer()
            
            // 4. Primary CTA Button ("Let's Get Creative!")
            Button(action: {
                // We'll hook up navigation to your Journey page here next!
            }) {
                Text("Let's Get Creative!")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("AccentOrange")) // #FF792E / #E8723B
                    .cornerRadius(28)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground").ignoresSafeArea()) // #FBF8ED cream background
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
