import SwiftUI

private let ideaCardColor = Color(hex: "FFF4CB")
private let backButtonColor = Color(hex: "F1EEE0")

// MARK: - Screen

struct Level1View: View {
    private let maxIdeas = 3
    private let prompt = "What if humans could fly for 10 minutes every day?"

    var stars: Int = 0
    var onComplete: () -> Void = {}

    private let starsPerIdea = 10

    @Environment(\.dismiss) private var dismiss
    @State private var ideas: [String] = []
    @State private var draft = ""
    @State private var showReward = false
    @State private var isAddingIdea = false          // يفتح بطاقة الإضافة
    @State private var showPause = false             // صفحة الـ Pause
    @State private var isDuplicate = false           // الفكرة مكررة؟
    @FocusState private var isFocused: Bool

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
        CGPoint(x: badgeFrame.minX + 21, y: badgeFrame.midY)
    }

    // شرط فتح الليفل اللي بعده
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
                VStack(spacing: 14) {
                    ForEach(Array(ideas.enumerated()), id: \.offset) { _, idea in
                        IdeaRow(text: idea, fill: ideaCardColor)
                            .transition(.scale.combined(with: .opacity))
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

            // بطاقة إضافة الفكرة
            if isAddingIdea {
                Color.black.opacity(0.08)
                    .ignoresSafeArea()
                    .onTapGesture(perform: closeCard)

                ideaCard
                    .padding(.horizontal, 42)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
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
            if isShowing { closeCard() }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: ideas)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isAddingIdea)
        .animation(.easeInOut(duration: 0.2), value: isDuplicate)
        .fullScreenCover(isPresented: $showReward) {
            RewardPopupView(
                xp: 10,
                coins: 350,
                stars: stars + ideas.count * starsPerIdea,
                tip: LevelTips.level1,                       // التيب من LevelHelpers
                onDone: {
                    showReward = false
                    // يفتح الليفل اللي بعده بس إذا جمع ٣٠ نجمة (يعني كتب ٣ أفكار)
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
                showPause = true
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
                Text("\(totalStars)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black)
                    .contentTransition(.numericText(value: Double(totalStars)))
            }
            .padding(.horizontal, 12)
            .frame(height: 33)
            .background(
                Capsule()
                    .fill(ideaCardColor)
                    .overlay(Capsule().strokeBorder(Color.lockedBorder, lineWidth: 1))
            )
            .scaleEffect(badgeBump ? 1.18 : 1)       // نبضة لما توصل النجمة
            .readFrame { badgeFrame = $0 }           // نحفظ مكان العداد
        }
    }

    // MARK: Add field

    private var addField: some View {
        Button {
            isAddingIdea = true
            // ننتظر شوي لين تطلع البطاقة، بعدين نفتح الكيبورد
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

    // البطاقة البيضاء (cancel / create + حقل الكتابة)
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
                // أول ما اليوزر يعدّل الكتابة، نخفي رسالة التكرار
                .onChange(of: draft) {
                    isDuplicate = false
                }

            // رسالة تطلع بس إذا الفكرة مكررة
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
        .readFrame { cardFrame = $0 }                // نحفظ مكان البطاقة
    }

    // MARK: Actions

    private var canCreate: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addIdea() {
        // 1) نشيل المسافات الزايدة من البداية والنهاية
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)

        // 2) إذا فاضية أو وصلنا الحد (٣ أفكار) نوقف
        guard !trimmed.isEmpty, ideas.count < maxIdeas else { return }

        // 3) إذا الفكرة مكررة → نطلع الرسالة ونوقف
        if ideas.isAlreadyWritten(trimmed) {
            isDuplicate = true
            return
        }

        // 4) الفكرة جديدة → نضيفها ونطيّر النجمة من مكان البطاقة
        ideas.append(trimmed)
        flyStart = CGPoint(x: cardFrame.midX, y: cardFrame.midY)
        closeCard()
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

    private func closeCard() {
        isFocused = false
        draft = ""
        isDuplicate = false
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
