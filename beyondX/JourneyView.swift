import SwiftUI

struct JourneyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            VStack(alignment: .leading, spacing: 7) {
                Text("Your\nCrative Journey") // Matches Sketch text
                    .font(.system(size: 38, weight: .black))
                    .foregroundColor(.black)
                
                Text("3 challenges to help you think beyond the ordinary")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.textSubtitle)
                    .frame(width: 329, alignment: .leading)
            }
            .padding(.leading, 35)
            .padding(.top, 40)
            
            Spacer().frame(height: 32)
            
            // Level Cards Stack
            VStack(spacing: 18) {
                // Level 1 (Completed)
                LevelCardView(
                    levelNumber: "1",
                    title: "What If .. ?",
                    state: .active,
                    mascotImageName: "Puzzled Robot"
                ) {}
                
                // Level 2 (Active)
                LevelCardView(
                    levelNumber: "2",
                    title: "This is not .. ?",
                    state: .locked,
                    mascotImageName: "Robot with Floating Shapes"
                ) {
                    // Navigate to Level 2 Challenge
                }
                
                // Level 3 (Locked)
                LevelCardView(
                    levelNumber: "3",
                    title: "Think beyond the object!",
                    state: .locked,
                    mascotImageName: "Robot with Idea"
                ) {}
            }
            .padding(.leading, 28)
            .padding(.trailing, 37)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.aappBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
}

struct JourneyView_Previews: PreviewProvider {
    static var previews: some View {
        JourneyView()
    }
}
