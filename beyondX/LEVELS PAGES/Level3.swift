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

    // Cup
    static let cupBodyTop    = Color(hex: 0x5FA3B9)
    static let cupBodyBottom = Color(hex: 0x4F8EA6)
    static let cupBase       = Color(hex: 0x4A8AA2)
    static let cupRim        = Color(hex: 0x6DB6CD)
    static let cupInside     = Color(hex: 0x3E8A69)
    static let cupInsideDark = Color(hex: 0x2C6A52)
    static let cupHandle     = Color(hex: 0x5159B4)
    static let cupStar       = Color(hex: 0x5B57B2)

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

struct Level3View: View {
    @Environment(\.dismiss) private var dismiss

    var stars: Int = 30
    var maxIdeas: Int = 3
    var onDone: ([String]) -> Void = { _ in }

    private let starsPerIdea = 10                          // NEW

    @State private var ideas: [String] = []
    @State private var showEditor = false
    @State private var draft = ""
    @FocusState private var editorFocused: Bool

    // NEW: نافذة المكافأة + النجوم وحركة النجمة الطايرة
    @State private var showReward = false
    @State private var earnedStars = 0
    @State private var badgeFrame: CGRect = .zero
    @State private var cardFrame: CGRect = .zero
    @State private var flyStart: CGPoint = .zero
    @State private var showFlyingStar = false
    @State private var starArrived = false
    @State private var badgeBump = false

    private var totalStars: Int { stars + earnedStars }    // NEW

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

            // NEW: النجمة اللي تطير للعداد
            if showFlyingStar {
                Image(systemName: "star.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Theme.star)
                    .shadow(color: .orange.opacity(0.4), radius: 8)
                    .scaleEffect(starArrived ? 0.4 : 1)
                    .position(starArrived
                              ? CGPoint(x: badgeFrame.minX + 19, y: badgeFrame.midY)
                              : flyStart)
                    .allowsHitTesting(false)
            }
        }
        .coordinateSpace(.named("screen"))                 // NEW
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .animation(.easeInOut(duration: 0.25), value: showEditor)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: ideas)
        // NEW: نافذة المكافأة بعد Done
        .fullScreenCover(isPresented: $showReward) {
            RewardPopupView(
                xp: 10,
                coins: 350,
                stars: stars + ideas.count * starsPerIdea,   // نفس العدد حتى لو النجمة لسا تطير
                tip: "Try looking at the object from a different place, like home, school or outdoors .",
                onDone: {
                    showReward = false
                    onDone(ideas)
                    dismiss()
                }
            )
        }
    }

    // MARK: Main content
    private var mainContent: some View {
        VStack(spacing: 0) {

            // MARK: Top bar
            HStack {
                BackCircleButton { dismiss() }
                Spacer()
                StarBadge(count: totalStars)                       // CHANGED
                    .scaleEffect(badgeBump ? 1.18 : 1)             // NEW: نبضة لما توصل النجمة
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("screen")) } action: {
                        badgeFrame = $0                            // NEW: مكان العداد
                    }
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
            CupView()
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
                    Button(action: finish) {                       // CHANGED: يفتح المكافأة
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

                Button("create", action: createIdea)
                    .font(Theme.medium(12))
                    .foregroundColor(canCreate ? Theme.orange : Theme.dashed)
                    .disabled(!canCreate)
            }

            TextEditor(text: $draft)
                .font(Theme.regular(13))
                .foregroundColor(Theme.title)
                .scrollContentBackground(.hidden)
                .focused($editorFocused)
                .padding(.horizontal, -5)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 161)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("screen")) } action: {
            cardFrame = $0                                         // NEW: مكان البطاقة
        }
    }

    // MARK: Actions
    private func openEditor() {
        draft = ""
        showEditor = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { editorFocused = true }
    }

    private func closeEditor() {
        editorFocused = false
        showEditor = false
    }

    private func createIdea() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, ideas.count < maxIdeas else { return }
        ideas.append(text)
        flyStart = CGPoint(x: cardFrame.midX, y: cardFrame.midY)   // NEW
        closeEditor()
        flyStarToBadge()                                           // NEW
    }

    // NEW: النجمة تطير من البطاقة للعداد، وبعدين يزيد ١٠
    private func flyStarToBadge() {
        starArrived = false
        showFlyingStar = true

        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.7)) {
                starArrived = true
            } completion: {
                showFlyingStar = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    earnedStars += starsPerIdea
                    badgeBump = true
                } completion: {
                    withAnimation(.spring(response: 0.3)) { badgeBump = false }
                }
            }
        }
    }

    // NEW
    private func finish() {
        showReward = true
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
                .contentTransition(.numericText(value: Double(count)))   // NEW: الرقم يتحرك
        }
        .padding(.horizontal, 10)
        .frame(height: 29)
        .background(Theme.badgeFill)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.badgeBorder, lineWidth: 1))
    }
}

// MARK: - Cup illustration (drawn in code, no image needed)

struct CupView: View {
    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width / 247
            ZStack {
                CupHandle()
                    .stroke(Theme.cupHandle, style: StrokeStyle(lineWidth: 18 * s, lineCap: .round))
                CupBase().fill(Theme.cupBase)
                CupBody().fill(
                    LinearGradient(colors: [Theme.cupBodyTop, Theme.cupBodyBottom],
                                   startPoint: .top, endPoint: .bottom)
                )
                CupStars().fill(Theme.cupStar)
                CupEllipse(x: 4, y: 0, w: 190, h: 38).fill(Theme.cupRim)
                CupEllipse(x: 14, y: 5.5, w: 170, h: 29).fill(Theme.cupInside)
                CupEllipse(x: 24, y: 16, w: 150, h: 18).fill(Theme.cupInsideDark)
            }
        }
        .aspectRatio(247.0 / 174.0, contentMode: .fit)
    }
}

private func cupPoint(_ x: CGFloat, _ y: CGFloat, _ rect: CGRect) -> CGPoint {
    CGPoint(x: rect.minX + x / 247 * rect.width,
            y: rect.minY + y / 174 * rect.height)
}

struct CupEllipse: Shape {
    var x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: CGRect(
            x: rect.minX + x / 247 * rect.width,
            y: rect.minY + y / 174 * rect.height,
            width: w / 247 * rect.width,
            height: h / 174 * rect.height
        ))
    }
}

struct CupBase: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: CGRect(
            x: rect.minX + 42 / 247 * rect.width,
            y: rect.minY + 146 / 174 * rect.height,
            width: 112 / 247 * rect.width,
            height: 26 / 174 * rect.height
        ))
    }
}

struct CupBody: Shape {
    func path(in rect: CGRect) -> Path {
        let m = { (x: CGFloat, y: CGFloat) -> CGPoint in cupPoint(x, y, rect) }
        var p = Path()
        p.move(to: m(6, 20))
        p.addCurve(to: m(48, 150), control1: m(-2, 75), control2: m(10, 128))
        p.addQuadCurve(to: m(142, 150), control: m(95, 164))
        p.addCurve(to: m(192, 18), control1: m(190, 128), control2: m(196, 75))
        p.closeSubpath()
        return p
    }
}

struct CupHandle: Shape {
    func path(in rect: CGRect) -> Path {
        let m = { (x: CGFloat, y: CGFloat) -> CGPoint in cupPoint(x, y, rect) }
        var p = Path()
        p.move(to: m(184, 36))
        p.addCurve(to: m(150, 128), control1: m(250, 20), control2: m(255, 120))
        return p
    }
}

struct CupStars: Shape {
    func path(in rect: CGRect) -> Path {
        let m = { (x: CGFloat, y: CGFloat) -> CGPoint in cupPoint(x, y, rect) }
        // (centerX, centerY, radius, rotation)
        let stars: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (28, 84, 13, -0.3),
            (95, 107, 19, 0.2),
            (151, 84, 16, 0.5),
            (54, 124, 15, 0.1),
            (126, 146, 12, -0.2)
        ]
        var p = Path()
        for (cx, cy, r, rot) in stars {
            for i in 0..<10 {
                let angle = rot + CGFloat(i) * .pi / 5 - .pi / 2
                let radius = i % 2 == 0 ? r : r * 0.45
                let pt = m(cx + cos(angle) * radius, cy + sin(angle) * radius)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
        }
        return p
    }
}

#Preview {
    NavigationStack { Level3View() }
}

