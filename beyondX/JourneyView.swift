import SwiftUI

struct JourneyView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showLevel1 = false
    @State private var level1Completed = false

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
                // Level 1
                LevelCardView(
                    levelNumber: "1",
                    title: "What If .. ?",
                    state: level1Completed ? .completed : .active,
                    mascotImageName: "Puzzled Robot"
                ) {
                    showLevel1 = true
                }

                // Level 2
                LevelCardView(
                    levelNumber: "2",
                    title: "This is not .. ?",
                    state: level1Completed ? .active : .locked,
                    mascotImageName: "Robot with Floating Shapes"
                ) {
                    // Navigate to Level 2 Challenge
                }

                // Level 3
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
        .fullScreenCover(isPresented: $showLevel1) {
            Level1View(onComplete: {
                level1Completed = true
                showLevel1 = false
            })
        }
    }
}

struct JourneyView_Previews: PreviewProvider {
    static var previews: some View {
        JourneyView()
    }
}
