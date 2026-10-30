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

    var stars: Int = 30      // ما نستخدمه الحين (النجوم صارت محفوظة)، بس خليناه عشان صفحة الماب ما يطلع فيها خطأ
    var maxIdeas: Int = 3
    var onDone: ([String]) -> Void = { _ in }

    private let levelNumber = 3                      // NEW: رقم الليفل (نستخدمه في الحفظ)
    private let starsPerIdea = 10

    @State private var ideas: [String] = []
    @State private var showEditor = false
    @State private var draft = ""
    @State private var showPause = false             // صفحة الـ Pause
    @State private var isDuplicate = false           // الفكرة مكررة؟
    @State private var duplicateText = ""            // آخر فكرة انرفضت لأنها مكررة
    @State private var showCelebration = false
    @FocusState private var editorFocused: Bool

    // NEW: النجوم محفوظة في الجوال (نفس المفتاح حق ليفل 1)
    // فتكمل من الرقم اللي وصل له، وأي تغيير ينحفظ تلقائياً
    @AppStorage(GameStorage.starsKey) private var totalStars = 0
    @State private var badgeBump = false

    // النجمة الطايرة (الحركة نفسها في LevelHelpers.swift)
    @State private var isStarFlying = false
    @State private var flyStart: CGPoint = .zero
    @State private var badgeFrame: CGRect = .zero
    @State private var cardFrame: CGRect = .zero

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
                    stars: totalStars,                            // CHANGED: النجوم المحفوظة كلها
                    tip: LevelTips.level3                         // التيب من LevelHelpers
                ) {
                    // يكمّل الليفل بس إذا جمع ٣٠ نجمة (يعني كتب ٣ أفكار)
                    if earnedInThisLevel >= starsToComplete {
                        onDone(ideas)

                        // NEW: خلّص اللعبة كاملة → نصفّر كل شي
                        // عشان لو فتح التطبيق مرة ثانية أو بغى يعيد، يبدأ من الصفر
                        GameStorage.resetAll()           // النجوم + الأفكار + الإجابة (المحفوظة في الجوال)
                        Level2Progress.shared.reset()    // رسم وأشكال ليفل ٢ (المحفوظة في الذاكرة)
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
        // NEW: أول ما تفتح الصفحة نرجّع الأفكار المحفوظة
        .onAppear {
            ideas = GameStorage.loadIdeas(level: levelNumber)
        }
        .pausePage(isPresented: $showPause,
                   message: PauseMessages.level3,      // NEW: عبارة الـ Pause حق هالليفل
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

            // MARK: Title — Sketch: SF Pro Bold 24، في النص، عرض 333، يبدأ y 172
            Text("Think of as many creative uses for the object as you can!")
                .font(Theme.bold(24))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 333, height: 87, alignment: .top)
                .padding(.top, 52)

            // MARK: Object — Sketch: 254 × 180، يبدأ y 316
            Image("cup")
                .resizable()
                .scaledToFit()
                .frame(width: 254, height: 180)
                .padding(.top, 57)
                .padding(.leading, 10)

            // MARK: Counter + ideas + Add Text — Sketch: Add Text على y 550
            ideasSection
                .padding(.horizontal, Theme.contentPadding)
                .padding(.top, 37)

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
                            .buttonShadow()                  // شادو Sketch
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
                            .font(Theme.regular(15))                       // Sketch: SF Pro Regular 15
                            .foregroundColor(Color(hex: 0x4A4A4A, opacity: 0.9))
                            .frame(maxWidth: .infinity)
                            .frame(height: 47)                             // Sketch: 313 × 47
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
                Button { createIdea() } label: {
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
                .submitLabel(.done)
                .onChange(of: draft) { _, newValue in
                    if newValue.contains("\n") {
                        // Enter انضغط: نشيل السطر الجديد ونرسل الفكرة
                        let cleaned = newValue.replacingOccurrences(of: "\n", with: "")
                        draft = cleaned
                        createIdea(cleaned)
                    } else if newValue.trimmingCharacters(in: .whitespacesAndNewlines) != duplicateText {
                        // اليوزر عدّل الكتابة → نخفي رسالة التكرار
                        isDuplicate = false
                    }
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
        duplicateText = ""
        showEditor = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { editorFocused = true }
    }

    private func closeEditor() {
        editorFocused = false
        draft = ""
        isDuplicate = false
        duplicateText = ""
        showEditor = false
    }

    private func createIdea(_ raw: String? = nil) {
        // 1) نشيل المسافات الزايدة من البداية والنهاية
        let text = (raw ?? draft).trimmingCharacters(in: .whitespacesAndNewlines)

        // 2) إذا فاضية أو وصلنا الحد نوقف
        guard !text.isEmpty, ideas.count < maxIdeas else { return }

        // 3) إذا الفكرة مكررة → نطلع الرسالة ونوقف
        if ideas.isAlreadyWritten(text) {
            duplicateText = text
            isDuplicate = true
            return
        }

        // 4) الفكرة جديدة → نضيفها ونطيّر النجمة من مكان البطاقة
        ideas.append(text)
        GameStorage.saveIdeas(ideas, level: levelNumber)   // NEW: نحفظ الأفكار في الجوال
        flyStart = CGPoint(x: cardFrame.midX, y: cardFrame.midY)
        closeEditor()
        isStarFlying = true                          // هذا اللي يطيّر النجمة

        // 5) نفتح البطاقة تلقائياً للفكرة اللي بعدها
        if ideas.count < maxIdeas {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !showCelebration && !showPause { openEditor() }
            }
        }
    }

    // لما توصل النجمة للعداد: يزيد ١٠ والعداد ينبض
    private func starArrived() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            totalStars += starsPerIdea               // CHANGED: يزيد وينحفظ تلقائياً
            badgeBump = true
        } completion: {
            withAnimation(.spring(response: 0.3)) { badgeBump = false }
        }
    }

    private func finish() {
        showCelebration = true
    }
}

// MARK: - Celebration page (animated)
//
// When the page opens:
//  1. confetti rains down
//  2. everything fades in together (mascot, titles, tip card, Done)
//     mascot: happy giggling eyes, mercury head, slow soft squeeze of the star
//  3. the journey: Level 1 grows and turns green -> line -> Level 2 -> line -> Level 3
//  4. the star badge counts up

struct CelebrationView: View {
    var stars: Int
    var tip: String = "Creativity has no limits. Keep exploring your potential and thinking beyond!"
    var onDone: () -> Void = {}

    @State private var shownStars = 0
    @State private var started = false
    @State private var showMascot = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var checked = 0            // levels turned green (0...3)
    @State private var lineFill: CGFloat = 0  // green line: 0, 0.5, 1
    @State private var popLevel = 0           // level that is popping right now
    @State private var showTip = false
    @State private var showDone = false
    @State private var confettiOn = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
            if confettiOn {
                CelebrationConfetti()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .task { await play() }
    }

    private var content: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                StarBadge(count: shownStars)
            }
            .padding(.horizontal, 32)
            .padding(.top, 13)

            CelebAnimatedMascot()
                .frame(width: 236, height: 225)
                .opacity(showMascot ? 1 : 0)
                .padding(.top, 32)

            Text("You Went Beyond!")
                .font(.system(size: 20, weight: .black))
                .fontWidth(.expanded)
                .foregroundColor(.black)
                .opacity(showTitle ? 1 : 0)
                .padding(.top, 29)

            Text("You’ve Completed Your Creative Journey")
                .font(Theme.bold(14))
                .foregroundColor(Theme.orange)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 4)
                .opacity(showSubtitle ? 1 : 0)
                .padding(.top, 16)

            JourneyProgress(checked: checked, lineFill: lineFill, popLevel: popLevel)
                .padding(.top, 38)

            TipCard(text: tip)
                .opacity(showTip ? 1 : 0)
                .padding(.top, 41)

            Spacer(minLength: 0)

            doneButton
                .padding(.bottom, 25)
        }
    }

    private var doneButton: some View {
        Button(action: onDone) {
            Text("Done")
                .font(Theme.regular(17))
                .foregroundColor(.white)
                .frame(width: 144, height: 50)
                .background(Theme.orange)
                .clipShape(Capsule())
                .buttonShadow()                              // شادو Sketch
        }
        .opacity(showDone ? 1 : 0)
    }

    private func play() async {
        if started { return }
        started = true

        if reduceMotion {
            shownStars = stars
            showMascot = true
            showTitle = true
            showSubtitle = true
            checked = 3
            lineFill = 1
            showTip = true
            showDone = true
            return
        }

        shownStars = max(0, stars - 30)
        confettiOn = true

        // everything fades in together
        withAnimation(.easeInOut(duration: 0.8)) {
            showMascot = true
            showTitle = true
            showSubtitle = true
            showTip = true
            showDone = true
        }
        try? await Task.sleep(for: .seconds(0.6))

        // star badge counts up quietly
        Task {
            while shownStars < stars {
                withAnimation(.easeOut(duration: 0.1)) { shownStars += 1 }
                try? await Task.sleep(for: .seconds(0.03))
            }
        }

        // the journey: Level 1 -> line -> Level 2 -> line -> Level 3
        for level in 1...3 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) {
                checked = level
                popLevel = level
            }
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { popLevel = 0 }
            if level < 3 {
                withAnimation(.easeInOut(duration: 0.5)) { lineFill = CGFloat(level) * 0.5 }
                try? await Task.sleep(for: .seconds(0.5))
            }
        }

    }
}

// MARK: Mascot: happy giggling eyes + mercury head (same style as the splash robot)
private struct CelebAnimatedMascot: View {
    @State private var flameFrame = 1
    @State private var hugSqueeze = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // centre of the eyes inside the image (so they squeeze around their own centre)
    private let eyesCentre = UnitPoint(x: 0.527, y: 0.292)
    private let starCentre = UnitPoint(x: 0.5905, y: 0.4652)

    var body: some View {
        ZStack {
            // mercury head (behind the helmet)
            ForEach(1...36, id: \.self) { frame in
                Image("Celeb Flame \(frame)")
                    .resizable().scaledToFit()
                    .opacity(flameFrame == frame ? 1 : 0)
            }
            Image("Celeb Body")
                .resizable().scaledToFit()
            // his hands + the star he hugs: a slow, soft squeeze (no spinning)
            Image("Celeb Hug")
                .resizable().scaledToFit()
                .scaleEffect(hugSqueeze ? 1.025 : 1, anchor: starCentre)
                .animation(reduceMotion ? nil : .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                           value: hugSqueeze)
                .onAppear { hugSqueeze = true }
            // happy eyes: a little "hehe" bounce every couple of seconds
            Image("Celeb Eyes")
                .resizable().scaledToFit()
                .keyframeAnimator(initialValue: CelebEyes(), repeating: !reduceMotion) { eyes, v in
                    eyes
                        .scaleEffect(x: 1, y: v.squash, anchor: eyesCentre)
                        .offset(y: v.lift)
                } keyframes: { _ in
                    KeyframeTrack(\.lift) {
                        CubicKeyframe(-2, duration: 0.3)
                        CubicKeyframe(0, duration: 0.3)
                        CubicKeyframe(-2, duration: 0.3)
                        CubicKeyframe(0, duration: 0.35)
                        LinearKeyframe(0, duration: 1.6)
                    }
                    KeyframeTrack(\.squash) {
                        CubicKeyframe(0.9, duration: 0.3)
                        CubicKeyframe(1, duration: 0.3)
                        CubicKeyframe(0.9, duration: 0.3)
                        CubicKeyframe(1, duration: 0.35)
                        LinearKeyframe(1, duration: 1.6)
                    }
                }
        }
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                flameFrame = flameFrame % 36 + 1
                try? await Task.sleep(for: .seconds(0.08))
            }
        }
    }
}

private struct CelebEyes {
    var lift: CGFloat = 0
    var squash: CGFloat = 1
}

// MARK: Progress line + checkmarks (a little journey: 1 -> 2 -> 3)
private struct JourneyProgress: View {
    var checked: Int = 3
    var lineFill: CGFloat = 1
    var popLevel: Int = 0
    private let green = Color(hex: 0x3FBF94)
    private let track = Color.black.opacity(0.08)

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(track)
                .frame(width: 200, height: 3)
                .padding(.top, 15)

            Rectangle()
                .fill(green)
                .frame(width: 200, height: 3)
                .scaleEffect(x: lineFill, y: 1, anchor: .leading)
                .padding(.top, 15)

            HStack(spacing: 0) {
                ForEach(1...3, id: \.self) { level in
                    CelebLevelCheck(level: level, isOn: checked >= level, green: green, track: track)
                        .scaleEffect(popLevel == level ? 1.3 : 1)
                        .frame(width: 100)
                }
            }
        }
        .frame(width: 300)
    }
}

private struct CelebLevelCheck: View {
    var level: Int
    var isOn: Bool
    var green: Color
    var track: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isOn ? green : track)
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.black)
                    .scaleEffect(isOn ? 1 : 0.2)
                    .opacity(isOn ? 1 : 0)
            }
            .frame(width: 34, height: 34)

            Text("Level \(level)")
                .font(Theme.medium(13))
                .foregroundColor(Color(hex: 0x373737))
        }
    }
}

// MARK: Confetti
private struct CelebConfettiPiece {
    var x: Double
    var delay: Double
    var speed: Double
    var drift: Double
    var freq: Double
    var phase: Double
    var spin: Double
    var w: Double
    var h: Double
    var color: Color
    var round: Bool

    static func random() -> CelebConfettiPiece {
        let colors: [Color] = [Theme.orange, Theme.star, Color(hex: 0x3FBF94), Color(hex: 0x7FD6B8), Color(hex: 0xFF9A5C)]
        return CelebConfettiPiece(
            x: Double.random(in: 0...1),
            delay: Double.random(in: 0...1.2),
            speed: Double.random(in: 180...320),
            drift: Double.random(in: 10...30),
            freq: Double.random(in: 2...4),
            phase: Double.random(in: 0...6.28),
            spin: Double.random(in: 180...540),
            w: Double.random(in: 6...10),
            h: Double.random(in: 8...14),
            color: colors.randomElement() ?? Theme.orange,
            round: Int.random(in: 0...3) == 0
        )
    }
}

private struct CelebrationConfetti: View {
    @State private var start = Date()
    @State private var pieces: [CelebConfettiPiece] = (0..<90).map { _ in CelebConfettiPiece.random() }
    private let duration: Double = 5

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                draw(in: &ctx, size: size, time: timeline.date.timeIntervalSince(start))
            }
        }
    }

    private func draw(in ctx: inout GraphicsContext, size: CGSize, time t: Double) {
        if t >= duration { return }
        let fade: Double = t > duration - 1 ? duration - t : 1

        for p in pieces {
            let lt = t - p.delay
            if lt <= 0 { continue }

            let y = -20 + p.speed * lt
            if y > Double(size.height) + 20 { continue }
            let x = p.x * Double(size.width) + p.drift * sin(lt * p.freq + p.phase)
            let flip = abs(cos(lt * 5 + p.phase))
            let rect = CGRect(x: -p.w / 2, y: -p.h * flip / 2, width: p.w, height: max(1, p.h * flip))
            let shape = p.round ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 1.5)

            var g = ctx
            g.opacity = fade
            g.translateBy(x: x, y: y)
            g.rotate(by: .degrees(p.spin * lt))
            g.fill(shape, with: .color(p.color))
        }
    }
}

private struct TipCard: View {
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Image("lightbulb")                  // the lightbulb from Assets (same as Sketch)
                .resizable()
                .scaledToFit()
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
            Image("goldenStar")                              // نجمة Sketch (حوافها ناعمة)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 20)
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
