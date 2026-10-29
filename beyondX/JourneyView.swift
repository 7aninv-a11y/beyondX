import SwiftUI

private enum JourneyLevel: Int, Identifiable {
    case level1, level2, level3

    var id: Int { rawValue }
}

struct JourneyView: View {
    @State private var activeLevel: JourneyLevel?
    @State private var level1Completed = false
    @State private var level2Completed = false
    @State private var level3Completed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Your\nCreative Journey")
                    .font(.system(size: 38, weight: .black))
                    .foregroundStyle(.black)

                Text("3 challenges to help you think beyond the ordinary")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: "625F5F"))
                    .frame(width: 329, alignment: .leading)
            }
            .padding(.leading, 35)
            .padding(.top, 40)

            Spacer().frame(height: 32)

            VStack(spacing: 18) {
                LevelCardView(
                    levelNumber: "1",
                    title: "What If .. ?",
                    state: level1Completed ? .completed : .active,
                    mascotImageName: "Puzzled Robot"
                ) {
                    activeLevel = .level1
                }

                LevelCardView(
                    levelNumber: "2",
                    title: "This is not .. ?",
                    state: level2Completed ? .completed :
                        (level1Completed ? .active : .locked),
                    mascotImageName: "Robot with Floating Shapes"
                ) {
                    guard level1Completed else { return }
                    activeLevel = .level2
                }

                LevelCardView(
                    levelNumber: "3",
                    title: "Think beyond....!",
                    state: level3Completed ? .completed :
                        (level2Completed ? .active : .locked),
                    mascotImageName: "Robot with Idea"
                ) {
                    guard level2Completed else { return }
                    activeLevel = .level3
                }
            }
            .padding(.leading, 28)
            .padding(.trailing, 37)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.aappBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(item: $activeLevel) { level in
            switch level {
            case .level1:
                Level1View {
                    level1Completed = true
                    activeLevel = nil
                }

            case .level2:
                Level2View {
                    level2Completed = true
                    activeLevel = nil
                }

            case .level3:
                Level3View { _ in
                    // بعد الاحتفال: كل الليفلز مفتوحة
                    level1Completed = true
                    level2Completed = true
                    level3Completed = true
                    activeLevel = nil
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        JourneyView()
    }
}
