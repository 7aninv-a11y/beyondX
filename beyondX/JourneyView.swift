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

    // NEW: النجوم المحفوظة (نفس المفتاح حق الليفلات)
    // أول ليفل = 0، وبعد كل ليفل يطلع مجموع اللي كسبه
    @AppStorage(GameStorage.starsKey) private var totalStars = 0

    // NEW: أنميشن فتح الليفل (شكل بس)
    // القفل الحقيقي نفسه (level1Completed ...)، هذا بس اللي ينعرض بالشاشة
    // ويلحق القفل الحقيقي بعد ما تتسكر صفحة الليفل، عشان تشوفين الحركة
    @State private var shownStep = 1                 // أي ليفل يبين مفتوح الحين
    @State private var activeBorderShown = false     // اللمعة أول ما تفتح الصفحة
    @State private var unlockingLevel: Int? = nil    // الليفل اللي ينفتح قفله الحين
    @State private var lockOpenLevel: Int? = nil     // القفل انفتح 🔓
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // الليفل المفتوح حسب القفل الحقيقي (4 = خلّص الكل)
    private var realStep: Int {
        if !level1Completed { return 1 }
        if !level2Completed { return 2 }
        if !level3Completed { return 3 }
        return 4
    }

    // حالة الكرت اللي تنعرض (نفس القفل الحقيقي بالضبط بعد ما تخلص الحركة)
    private func shownState(_ level: Int) -> LevelState {
        if level < shownStep { return .completed }
        if level == shownStep { return .active }
        return .locked
    }

    private func cardAnimation(_ level: Int) -> (unlocking: Bool, lockOpen: Bool) {
        (unlockingLevel == level, lockOpenLevel == level)
    }

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
                    state: shownState(1),
                    mascotImageName: "Puzzled Robot",
                    showActiveBorder: activeBorderShown,
                    isUnlocking: cardAnimation(1).unlocking,
                    lockIsOpen: cardAnimation(1).lockOpen
                ) {
                    activeLevel = .level1
                }

                LevelCardView(
                    levelNumber: "2",
                    title: "This is not .. ?",
                    state: shownState(2),
                    mascotImageName: "Robot with Floating Shapes",
                    showActiveBorder: activeBorderShown,
                    isUnlocking: cardAnimation(2).unlocking,
                    lockIsOpen: cardAnimation(2).lockOpen
                ) {
                    guard level1Completed else { return }
                    activeLevel = .level2
                }

                LevelCardView(
                    levelNumber: "3",
                    title: "Think beyond..!",
                    state: shownState(3),
                    mascotImageName: "Robot with Idea",
                    showActiveBorder: activeBorderShown,
                    isUnlocking: cardAnimation(3).unlocking,
                    lockIsOpen: cardAnimation(3).lockOpen
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
        // NEW: عداد النجوم فوق يمين (فوق الصفحة، ما يحرك أي شي)
        .overlay(alignment: .topTrailing) {
            JourneyStarBadge(count: totalStars)
                .padding(.top, 13)
                .padding(.trailing, 41)
        }
        .background(Color.aappBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        // NEW: اللمعة أول ما تفتح الصفحة
        .task {
            shownStep = realStep
            if reduceMotion { activeBorderShown = true; return }
            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.easeInOut(duration: 0.8)) { activeBorderShown = true }
        }
        // NEW: لما يخلص ليفل → نشغل حركة فتح الليفل اللي بعده
        .onChange(of: realStep) { _, newStep in
            Task { await moveToStep(newStep) }
        }
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

// MARK: - عداد النجوم (نفس شكل ليفل ١)

private struct JourneyStarBadge: View {
    var count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image("goldenStar")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 22)
            Text("\(count)")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.black)
                .contentTransition(.numericText(value: Double(count)))
        }
        .padding(.horizontal, 12)
        .frame(height: 33)
        .background(
            Capsule()
                .fill(Color(hex: "FFF4CB"))
                .overlay(Capsule().strokeBorder(Color.lockedBorder, lineWidth: 1))
        )
    }
}

// MARK: - حركة فتح الليفل اللي بعده
extension JourneyView {

    /// 1) ننتظر صفحة الليفل تتسكر
    /// 2) الليفل اللي خلص يصير ✓ والبوردر البرتقالي يختفي بنعومة
    /// 3) القفل يهتز وينفتح 🔓
    /// 4) الرمادي يروح ويطلع السهم البرتقالي
    /// 5) البوردر البرتقالي يطلع بنعومة على الليفل الجديد
    fileprivate func moveToStep(_ newStep: Int) async {
        guard newStep != shownStep else { return }

        // بدون أنميشن: لو "تقليل الحركة" شغال، أو رجعنا لورا
        if reduceMotion || newStep < shownStep {
            shownStep = newStep
            return
        }

        try? await Task.sleep(for: .seconds(0.8))
        let unlocking: Int? = newStep <= 3 ? newStep : nil

        withAnimation(.easeInOut(duration: 0.7)) {
            activeBorderShown = false
            unlockingLevel = unlocking
            shownStep = newStep
        }
        guard let level = unlocking else { return }

        try? await Task.sleep(for: .seconds(0.9))
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            lockOpenLevel = level
        }

        try? await Task.sleep(for: .seconds(0.9))
        withAnimation(.easeInOut(duration: 1.4)) {      // الرمادي يتلاشى على مهله
            unlockingLevel = nil
            lockOpenLevel = nil
        }

        try? await Task.sleep(for: .seconds(1.0))
        withAnimation(.easeInOut(duration: 1.0)) {
            activeBorderShown = true
        }
    }
}

#Preview {
    NavigationStack {
        JourneyView()
    }
}
