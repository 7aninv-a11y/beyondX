import SwiftUI

enum Theme {

    // MARK: Colors
    static let background   = Color(hex: 0xFBF8EE)
    static let title        = Color(hex: 0x111111)
    static let subtitle     = Color(hex: 0x6B6B66)
    static let circleButton = Color(hex: 0xF1EEE6)
    static let badgeFill    = Color(hex: 0xFDF5DC)
    static let badgeBorder  = Color(hex: 0xE5C77A)
    static let star         = Color(hex: 0xFFC933)
    static let dashed       = Color(hex: 0xB5B2A8)
    static let addText      = Color(hex: 0x77756F)
    static let note         = Color(hex: 0xFCF0C6)
    static let orange       = Color(hex: 0xDE7446)

    // MARK: Fonts
    static func bold(_ size: CGFloat) -> Font    { .system(size: size, weight: .bold) }
    static func medium(_ size: CGFloat) -> Font  { .system(size: size, weight: .medium) }
    static func regular(_ size: CGFloat) -> Font { .system(size: size, weight: .regular) }

    // MARK: Layout
    static let screenPadding: CGFloat = 39
    static let contentPadding: CGFloat = 44
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Level3View

struct Level3View: View {
    @Environment(\.dismiss) private var dismiss

    var stars: Int = 30
    var maxIdeas: Int = 3
    var onDone: ([String]) -> Void = { _ in }

    private let starsPerIdea = 10

    @State private var ideas: [String] = []
    @State private var showEditor = false
    @State private var draft = ""
    @State private var showPause = false             // صفحة الـ Pause
    @State private var isDuplicate = false           // الفكرة مكررة؟
    @State private var showCelebration = false
    @FocusState private var editorFocused: Bool

    // النجوم
    @State private var earnedStars = 0
    @State private var badgeBump = false

    // النجمة الطايرة (الحركة نفسها في LevelHelpers.swift)
    @State private var isStarFlying = false
    @State private var flyStart: CGPoint = .zero
    @State private var badgeFrame: CGRect = .zero
    @State private var cardFrame: CGRect = .zero

    private var totalStars: Int { stars + earnedStars }

    // النقطة اللي توصل لها النجمة (مكان النجمة الصغيرة في العداد)
    private var badgeStarPoint: CGPoint {
        CGPoint(x: badgeFrame.minX + 19, y: badgeFrame.midY)
    }

    // شرط إكمال الليفل (نفس ليفل 1: ٣٠ نجمة = ٣ أفكار)
    private let starsToComplete = 30
    private var earnedInThisLevel: Int { ideas.count * starsPerIdea }

    private var canCreate: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.background.ignoresSafeArea()

            mainContent
                .blur(radius: showEditor ? 10 : 0)

            if showEditor {
                Color.black.opacity(0.08)
                    .ignoresSafeArea()
                    .onTapGesture { closeEditor() }
                    .transition(.opacity)

                editorCard
                    .padding(.leading, 40)
                    .padding(.trailing, 50)
                    .padding(.top, 259)
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
            }

            // صفحة الاحتفال داخل نفس الصفحة
            if showCelebration {
                CelebrationView(
                    stars: stars + ideas.count * starsPerIdea,
                    tip: LevelTips.level3                         // التيب من LevelHelpers
                ) {
                    // يكمّل الليفل بس إذا جمع ٣٠ نجمة (يعني كتب ٣ أفكار)
                    if earnedInThisLevel >= starsToComplete {
                        onDone(ideas)
                    }
                    dismiss()
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        // النجمة الطايرة من الملف المشترك
        .flyingStar(isFlying: $isStarFlying, from: flyStart, to: badgeStarPoint) {
            starArrived()
        }
        .coordinateSpace(.named("screen"))
        .pausePage(isPresented: $showPause,
                   onPause: { dismiss() },           // زر pause يرجع للماب
                   onBack: { })                      // السهم يسكّر الـ Pause ويرجع لليفل
        .onChange(of: showPause) { _, isShowing in   // يسكّر الكيبورد والبطاقة إذا انفتح الـ Pause
            if isShowing { closeEditor() }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut(duration: 0.25), value: showEditor)
        .animation(.easeInOut(duration: 0.35), value: showCelebration)
        .animation(.easeInOut(duration: 0.2), value: isDuplicate)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: ideas)
    }

    // MARK: Main content
    private var mainContent: some View {
        VStack(spacing: 0) {

            // MARK: Top bar
            HStack {
                BackCircleButton { showPause = true }        // يفتح الـ Pause
                Spacer()
                StarBadge(count: totalStars)
                    .scaleEffect(badgeBump ? 1.18 : 1)       // نبضة لما توصل النجمة
                    .readFrame { badgeFrame = $0 }           // نحفظ مكان العداد
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 13)

            // MARK: Title + subtitle
            VStack(spacing: 12) {
                Text("Think beyond the object!")
                    .font(Theme.bold(26))
                    .foregroundColor(Theme.title)

                Text("Think of as many creative uses for the object as you can!")
                    .font(Theme.regular(13))
                    .lineSpacing(2)
                    .foregroundColor(Theme.subtitle)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 47)

            // MARK: Object
            Image("cup")
                .resizable()
                .scaledToFit()
                .frame(width: 247, height: 174)
                .padding(.top, 72)
                .padding(.leading, 24)

            // MARK: Counter + ideas + Add Text
            ideasSection
                .padding(.horizontal, Theme.contentPadding)
                .padding(.top, 41)

            Spacer(minLength: 0)

            // MARK: Done
            ZStack {
                if !ideas.isEmpty {
                    Button(action: finish) {
                        Text("Done")
                            .font(Theme.medium(14))
                            .foregroundColor(.white)
                            .frame(width: 138, height: 48)
                            .background(Theme.orange)
                            .clipShape(Capsule())
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 48)
            .padding(.bottom, 25)
        }
    }

    // MARK: Ideas section
    private var ideasSection: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("\(ideas.count)/\(maxIdeas)")
                .font(Theme.regular(11))
                .foregroundColor(Theme.dashed)
                .padding(.trailing, 6)

            VStack(spacing: 14) {
                ForEach(Array(ideas.enumerated()), id: \.offset) { _, idea in
                    Text(idea)
                        .font(Theme.regular(13))
                        .foregroundColor(Theme.title)
                        .lineLimit(1)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .background(Theme.note)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 3)
                        .transition(.scale.combined(with: .opacity))
                }

                if ideas.count < maxIdeas {
                    Button(action: openEditor) {
                        Text("+ Add Text")
                            .font(Theme.regular(13))
                            .foregroundColor(Theme.addText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .contentShape(Rectangle())
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(
                                        Theme.dashed,
                                        style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])
                                    )
                            )
                    }
                }
            }
        }
    }

    // MARK: Editor popup
    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button("cancel", action: closeEditor)
                    .font(Theme.bold(12))
                    .foregroundColor(Theme.subtitle)

                Spacer()

                // زر create برتقالي (نفس ليفل 1)
                Button(action: createIdea) {
                    Text("create")
                        .font(Theme.medium(12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 26)
                        .background(Capsule().fill(Theme.orange))
                }
                .opacity(canCreate ? 1 : 0.4)        // باهت لين يكتب شي
                .disabled(!canCreate)
            }

            TextEditor(text: $draft)
                .font(Theme.regular(13))
                .foregroundColor(Theme.title)
                .scrollContentBackground(.hidden)
                .focused($editorFocused)
                .padding(.horizontal, -5)
                // أول ما اليوزر يعدّل الكتابة، نخفي رسالة التكرار
                .onChange(of: draft) {
                    isDuplicate = false
                }

            // رسالة تطلع بس إذا الفكرة مكررة
            if isDuplicate {
                Text("You already wrote this idea, try a different one!")
                    .font(Theme.regular(11))
                    .foregroundColor(.red)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 161)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
        .readFrame { cardFrame = $0 }                // نحفظ مكان البطاقة
    }

    // MARK: Actions
    private func openEditor() {
        draft = ""
        isDuplicate = false
        showEditor = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { editorFocused = true }
    }

    private func closeEditor() {
        editorFocused = false
        draft = ""
        isDuplicate = false
        showEditor = false
    }

    private func createIdea() {
        // 1) نشيل المسافات الزايدة من البداية والنهاية
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)

        // 2) إذا فاضية أو وصلنا الحد نوقف
        guard !text.isEmpty, ideas.count < maxIdeas else { return }

        // 3) إذا الفكرة مكررة → نطلع الرسالة ونوقف
        if ideas.isAlreadyWritten(text) {
            isDuplicate = true
            return
        }

        // 4) الفكرة جديدة → نضيفها ونطيّر النجمة من مكان البطاقة
        ideas.append(text)
        flyStart = CGPoint(x: cardFrame.midX, y: cardFrame.midY)
        closeEditor()
        isStarFlying = true                          // هذا اللي يطيّر النجمة
    }

    // لما توصل النجمة للعداد: يزيد ١٠ والعداد ينبض
    private func starArrived() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            earnedStars += starsPerIdea
            badgeBump = true
        } completion: {
            withAnimation(.spring(response: 0.3)) { badgeBump = false }
        }
    }

    private func finish() {
        showCelebration = true
    }
}

// MARK: - Celebration page

struct CelebrationView: View {
    var stars: Int
    var tip: String = "Creativity has no limits. Keep exploring your potential and thinking beyond!"
    var onDone: () -> Void = {}

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    StarBadge(count: stars)
                }
                .padding(.horizontal, 32)
                .padding(.top, 13)

                Image("CelebrationMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 236, height: 225)
                    .padding(.top, 32)

                Text("You Went Beyond!")
                    .font(.system(size: 20, weight: .black))
                    .fontWidth(.expanded)
                    .foregroundColor(.black)
                    .padding(.top, 29)

                Text("You’ve Completed Your Creative Journey")
                    .font(Theme.bold(14))
                    .foregroundColor(Theme.orange)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 4)
                    .padding(.top, 16)

                JourneyProgress()
                    .padding(.top, 38)

                TipCard(text: tip)
                    .padding(.top, 41)

                Spacer(minLength: 0)

                Button(action: onDone) {
                    Text("Done")
                        .font(Theme.regular(17))
                        .foregroundColor(.white)
                        .frame(width: 144, height: 50)
                        .background(Theme.orange)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                }
                .padding(.bottom, 25)
            }
        }
    }
}

private struct JourneyProgress: View {
    private let green = Color(hex: 0x3FBF94)

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(green)
                .frame(width: 200, height: 3)
                .padding(.top, 15)

            HStack(spacing: 0) {
                ForEach(1...3, id: \.self) { level in
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.black)
                            .frame(width: 34, height: 34)
                            .background(green)
                            .clipShape(Circle())

                        Text("Level \(level)")
                            .font(Theme.medium(13))
                            .foregroundColor(Color(hex: 0x373737))
                    }
                    .frame(width: 100)
                }
            }
        }
        .frame(width: 300)
    }
}

private struct TipCard: View {
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 26))
                .foregroundColor(Theme.star)
                .frame(width: 45, height: 39)
                .padding(.top, 17)
                .padding(.leading, 3)

            VStack(alignment: .leading, spacing: 4) {
                Text("Tip :")
                Text(text)
            }
            .font(Theme.regular(17))
            .foregroundColor(Color(hex: 0x060606))
            .padding(.top, 20)
            .padding(.trailing, 20)
        }
        .frame(maxWidth: 304, alignment: .leading)
        .frame(height: 143, alignment: .top)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color(hex: 0xE8E8E8), lineWidth: 1))
        .shadow(color: .black.opacity(0.1), radius: 25, x: 0, y: 4)
    }
}

// MARK: - Components

struct BackCircleButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.left")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.title)
                .frame(width: 44, height: 44)
                .background(Theme.circleButton)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black.opacity(0.05), lineWidth: 0.5))
        }
    }
}

struct StarBadge: View {
    var count: Int
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: 18))
                .foregroundColor(Theme.star)
            Text("\(count)")
                .font(Theme.bold(14))
                .foregroundColor(Theme.title)
                .contentTransition(.numericText(value: Double(count)))
        }
        .padding(.horizontal, 10)
        .frame(height: 29)
        .background(Theme.badgeFill)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.badgeBorder, lineWidth: 1))
    }
}

#Preview("Level 3") {
    NavigationStack { Level3View() }
}

#Preview("Celebration") {
    CelebrationView(stars: 60)
}
