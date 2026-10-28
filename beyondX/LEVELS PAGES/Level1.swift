import SwiftUI

private let ideaCardColor = Color(hex: "FFF4CB")
private let backButtonColor = Color(hex: "F1EEE0")

// MARK: - Screen

struct Level1View: View {
    private let maxIdeas = 3
    private let prompt = "What if humans could fly for 10 minutes every day?"

    var stars: Int = 0                                // CHANGED: البداية صفر
    var onComplete: () -> Void = {}

    private let starsPerIdea = 10                     // NEW

    @Environment(\.dismiss) private var dismiss
    @State private var ideas: [String] = []
    @State private var draft = ""
    @State private var showReward = false
    @State private var isAddingIdea = false          // NEW: يفتح بطاقة الإضافة
    @State private var showPause = false             // NEW: صفحة الـ Pause
    @FocusState private var isFocused: Bool

    // NEW: هل الفكرة اللي كتبها اليوزر مكررة؟
    // تكون false في البداية، وتصير true إذا كتب فكرة كتبها قبل
    @State private var isDuplicate = false

    // NEW: النجوم وحركة النجمة الطايرة
    @State private var earnedStars = 0
    @State private var badgeFrame: CGRect = .zero
    @State private var cardFrame: CGRect = .zero
    @State private var flyStart: CGPoint = .zero
    @State private var showFlyingStar = false
    @State private var starArrived = false
    @State private var badgeBump = false

    private var totalStars: Int { stars + earnedStars }   // NEW

    // NEW: شرط فتح الليفل اللي بعده
    private let starsToUnlockNext = 30
    private var earnedInThisLevel: Int { ideas.count * starsPerIdea }

    var body: some View {
        ZStack {
            Color.aappBackground
                .ignoresSafeArea()
                .onTapGesture { isFocused = false }

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 42)
                    .padding(.top, 12)

                // Title
                Text("What If ...?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.top, 14)

                Text("Write 3 different ideas !")
                    .font(.system(size: 17))
                    .foregroundStyle(Color(white: 0.25))
                    .padding(.top, 14)

                // Illustration (image named "FlyingIdea" in Assets)
                Image("FlyingIdea")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 314)
                    .padding(.horizontal, 44)
                    .padding(.top, 60)

                // Question
                Text(prompt)
                    .font(.system(size: 14))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .padding(.top, 14)

                // Ideas + add field
                VStack(spacing: 14) {                         // CHANGED: نفس المسافة في Level 3
                    ForEach(Array(ideas.enumerated()), id: \.offset) { _, idea in
                        IdeaRow(text: idea, fill: ideaCardColor)
                            .transition(.scale.combined(with: .opacity))   // CHANGED: نفس حركة Level 3
                    }

                    if ideas.count < maxIdeas {
                        addField
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 41)
                .padding(.top, 70)

                Spacer(minLength: 16)

                // Done (appears after the first idea)
                if !ideas.isEmpty {
                    DoneButton(action: finish)
                        .padding(.bottom, 30)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }

            // NEW: بطاقة إضافة الفكرة (level 1 v2)
            if isAddingIdea {
                Color.black.opacity(0.08)
                    .ignoresSafeArea()
                    .onTapGesture(perform: closeCard)

                ideaCard
                    .padding(.horizontal, 42)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }

            // NEW: النجمة اللي تطير للعداد
            if showFlyingStar {
                Image(systemName: "star.fill")
                    .font(.system(size: starArrived ? 18 : 44))
                    .foregroundStyle(Color(hex: "F5C518"))
                    .shadow(color: .orange.opacity(0.4), radius: 8)
                    .position(starArrived
                              ? CGPoint(x: badgeFrame.minX + 21, y: badgeFrame.midY)
                              : flyStart)
                    .allowsHitTesting(false)
            }
        }
        .coordinateSpace(.named("screen"))           // NEW
        .pausePage(isPresented: $showPause,          // NEW: الـ Pause
                   onPause: { dismiss() },           // زر pause يرجع للماب
                   onBack: { })                      // السهم يسكّر الـ Pause ويرجع لليفل
        .onChange(of: showPause) { _, isShowing in   // NEW: يسكّر الكيبورد والبطاقة إذا انفتح الـ Pause
            if isShowing { closeCard() }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: ideas)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isAddingIdea)   // NEW
        .animation(.easeInOut(duration: 0.2), value: isDuplicate)                         // NEW: رسالة التكرار تطلع بنعومة
        .fullScreenCover(isPresented: $showReward) {
            RewardPopupView(
                xp: 10,
                coins: 350,
                stars: stars + ideas.count * starsPerIdea,   // CHANGED: نفس عدد النجوم حتى لو النجمة لسا تطير
                tip: "Try looking at the object from a different place, like home, school or outdoors .",
                onDone: {
                    showReward = false
                    // NEW: يفتح الليفل اللي بعده بس إذا جمع ٣٠ نجمة (يعني كتب ٣ أفكار)
                    if earnedInThisLevel >= starsToUnlockNext {
                        onComplete()
                    }
                    dismiss()
                }
            )
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            Button {
                showPause = true                      // CHANGED: كان dismiss()، الحين يفتح الـ Pause
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(backButtonColor))
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color(hex: "F5C518"))
                Text("\(totalStars)")                                 // CHANGED
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black)
                    .contentTransition(.numericText(value: Double(totalStars)))   // NEW: الرقم يتحرك
            }
            .padding(.horizontal, 12)
            .frame(height: 33)
            .background(
                Capsule()
                    .fill(ideaCardColor)
                    .overlay(Capsule().strokeBorder(Color.lockedBorder, lineWidth: 1))
            )
            .scaleEffect(badgeBump ? 1.18 : 1)                         // NEW: نبضة لما توصل النجمة
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("screen")) } action: {
                badgeFrame = $0                                        // NEW: مكان العداد
            }
        }
    }

    // MARK: Add field

    // CHANGED: صار زر يفتح البطاقة بدل ما تكتبين مباشرة فيه (نفس الشكل)
    private var addField: some View {
        Button {
            isAddingIdea = true
            // CHANGED: ننتظر شوي لين تطلع البطاقة، بعدين نفتح الكيبورد
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isFocused = true
            }
        } label: {
            Text("+ Add Text")
                .font(.system(size: 17))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .frame(height: 47)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.gray.opacity(0.6),
                                      style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
        }
    }

    // NEW: البطاقة البيضاء (cancel / create + حقل الكتابة)
    // CHANGED: نفس تصميم بطاقة الكتابة في Level 3
    private var ideaCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button("cancel", action: closeCard)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "6B6B66"))

                Spacer()

                // زر create برتقالي
                Button(action: addIdea) {
                    Text("create")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 26)
                        .background(Capsule().fill(Color.primaryOrange))
                }
                .opacity(canCreate ? 1 : 0.4)     // باهت لين يكتب شي
                .disabled(!canCreate)
            }

            TextField(prompt, text: $draft, axis: .vertical)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "111111"))
                .lineLimit(1...6)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit(addIdea)
                // NEW: أول ما اليوزر يعدّل الكتابة، نخفي رسالة التكرار
                .onChange(of: draft) {
                    isDuplicate = false
                }

            // NEW: رسالة تطلع بس إذا الفكرة مكررة
            if isDuplicate {
                Text("You already wrote this idea, try a different one!")
                    .font(.system(size: 11))
                    .foregroundColor(.red)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 161)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("screen")) } action: {
            cardFrame = $0                                             // NEW: مكان البطاقة
        }
    }

    // MARK: Actions

    // NEW
    private var canCreate: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // NEW: تشيك هل الفكرة موجودة من قبل في قائمة الأفكار
    // نحوّل الحروف كلها small عشان "Fly" و "fly" تنحسب نفس الفكرة
    private func isAlreadyWritten(_ newIdea: String) -> Bool {
        let newIdeaSmall = newIdea.lowercased()

        for oldIdea in ideas {
            if oldIdea.lowercased() == newIdeaSmall {
                return true     // لقينا نفس الفكرة → مكررة
            }
        }
        return false            // ما لقيناها → فكرة جديدة
    }

    private func addIdea() {
        // 1) نشيل المسافات الزايدة من البداية والنهاية
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)

        // 2) إذا فاضية أو وصلنا الحد (٣ أفكار) نوقف
        guard !trimmed.isEmpty, ideas.count < maxIdeas else { return }

        // 3) NEW: إذا الفكرة مكررة → نطلع الرسالة ونوقف (ما نضيفها وما نعطي نجوم)
        if isAlreadyWritten(trimmed) {
            isDuplicate = true
            return
        }

        // 4) الفكرة جديدة → نضيفها ونطيّر النجمة
        ideas.append(trimmed)
        flyStart = CGPoint(x: cardFrame.midX, y: cardFrame.midY)    // NEW
        closeCard()                                   // CHANGED: كانت draft = ""
        flyStarToBadge()                              // NEW
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
    private func closeCard() {
        isFocused = false
        draft = ""
        isDuplicate = false                           // NEW: نصفّر رسالة التكرار
        isAddingIdea = false
    }

    private func finish() {
        showReward = true
    }
}

// MARK: - Components

private struct IdeaRow: View {
    let text: String
    let fill: Color

    // CHANGED: نفس تصميم الفكرة بعد الإضافة في Level 3 (بدون حدود + شادو)
    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(Color(hex: "111111"))
            .lineLimit(1)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 45)
            .background(Color(hex: "FCF0C6"))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 3)
    }
}

private struct DoneButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Done")
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .frame(width: 144, height: 50)
                .background(Capsule().fill(Color.primaryOrange))
        }
    }
}

// MARK: - Preview

#Preview {
    Level1View()
}
