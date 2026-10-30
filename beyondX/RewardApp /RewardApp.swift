//
//  RewardPopupView.swift
//  صفحة المكافأة (Reward Popup)
//

import SwiftUI


// ============================================================
// الصفحة نفسها
// ============================================================
// ملاحظة: Color(hex:) و Color.primaryOrange موجودين في ملف الثيم،
// فنستخدمهم هنا مباشرة بدون ما نعيد كتابتهم.

struct RewardPopupView: View {

    // ---------- البيانات اللي تجي من برا (من الليفل) ----------
    // الصفحة ما تحسبها بنفسها، فقط تعرضها
    let xp: Int            // ما تنعرض الحين، بس خليناها عشان الليفلات ترسلها وما يطلع خطأ
    let coins: Int         // ما تنعرض الحين، نفس السبب
    let stars: Int         // عدد النجوم اللي جمعها المستخدم، مثال: 30
    let tip: String        // نص النصيحة

    // دالة تنفذ لما المستخدم يضغط زر Done
    // الصفحة اللي فتحت الـ Popup هي اللي تقرر وش يصير (تقفله مثلاً)
    var onDone: () -> Void

    // NEW: الرقم اللي ينعرض في "You earned" (يعد من 0 لين يوصل للنجوم)
    @State private var shownStars = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // ---------- الألوان من Sketch (reward level 1 / reward level 2) ----------
    let background = Color(hex: "FBF8ED")   // خلفية الصفحة + لون صندوق التيب
    let borderGray = Color(hex: "E8E8E8")   // حدود صندوق التيب
    let textBlack  = Color(hex: "060606")   // لون النصوص

    // ---------- شكل الصفحة ----------
    var body: some View {

        ZStack {

            background.ignoresSafeArea()

            VStack(spacing: 0) {

                // مسافة فوق العنوان — Sketch: العنوان يبدأ y 144
                Spacer().frame(height: 74)

                // ----------------------------------------
                // أ) العنوان الكبير — Sketch: عرض 252
                // ----------------------------------------
                Text("AWESOME !")
                    .font(.system(size: 42, weight: .black))
                    .foregroundColor(textBlack)

                // ----------------------------------------
                // ب) الروبوت ماسك النجمة — Sketch: 200 × 240، y 247
                // ----------------------------------------
                // NEW: الروبوت متحرك (الزئبق + الوشاح + العيون + النجمة)
                // نفس الصورة "mascot" بس مقسومة طبقات، فمكانه وحجمه ما تغيروا
                RewardAnimatedMascot()
                    .frame(width: 200, height: 240)
                    .padding(.top, 62)

                // ----------------------------------------
                // ج) النجوم — Sketch: SF Pro Bold 20، بدون صورة نجمة، y 541
                // ----------------------------------------
                Text("You earned:+\(shownStars)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .contentTransition(.numericText(value: Double(shownStars)))   // NEW: الرقم يتبدل بنعومة
                    .padding(.top, 44)
                    .task { await countUpStars() }                                // NEW: يعد من 0 لين يوصل

                // ----------------------------------------
                // د) صندوق النصيحة — Sketch: 304 × 143، y 585
                // ----------------------------------------
                tipBox
                    .padding(.top, 24)

                Spacer()

                // ----------------------------------------
                // هـ) زر Done — Sketch: 144 × 50، y 763
                // ----------------------------------------
                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .frame(width: 144, height: 50)
                        .background(Capsule().fill(Color.primaryOrange))
                        .buttonShadow()                      // شادو Sketch
                }
                .padding(.bottom, 30)
            }
        }
    }

    // ============================================================
    // NEW: عدّاد "You earned" يزيد لين يوصل لعدد النجوم
    // ============================================================
    private func countUpStars() async {
        guard stars > 0 else { shownStars = 0; return }
        if reduceMotion { shownStars = stars; return }
        try? await Task.sleep(for: .seconds(0.4))                 // ننتظر الصفحة تطلع
        let step = max(1, stars / 30)                             // ~30 خطوة مهما كان الرقم
        while shownStars < stars && !Task.isCancelled {
            withAnimation(.easeOut(duration: 0.12)) {
                shownStars = min(stars, shownStars + step)
            }
            try? await Task.sleep(for: .seconds(0.04))
        }
    }

    // ============================================================
    // صندوق النصيحة
    // ============================================================
    private var tipBox: some View {

        HStack(alignment: .top, spacing: 2) {

            // أيقونة اللمبة — Sketch: 45 × 39
            Image("lightbulb")
                .resizable()
                .scaledToFit()
                .frame(width: 45, height: 39)
                .padding(.top, 17)

            // "Tip :" وتحتها النصيحة — Sketch: SF Pro Light 18
            VStack(alignment: .leading, spacing: 6) {
                Text("Tip :")
                Text(tip)
                    .padding(.leading, 3)
                    .fixedSize(horizontal: false, vertical: true)   // ينزل سطر بدل ما ينقص
            }
            .font(.system(size: 18, weight: .light))
            .foregroundColor(textBlack)
            .frame(width: 236, alignment: .leading)
            .padding(.top, 24)

            Spacer(minLength: 0)
        }
        .padding(.leading, 2)
        .frame(width: 304, height: 143, alignment: .topLeading)

        // الخلفية + الشادو — Sketch: أسود 10%، y 4، Blur 50
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(background)
                .shadow(color: Color.black.opacity(0.10), radius: 25, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(borderGray, lineWidth: 1)
        )
    }
}


// ============================================================
// NEW: الروبوت المتحرك حق الريورد
// ============================================================
// نفس رسمة "mascot" مقسومة طبقات (كلها نفس المقاس، فتنركب فوق بعض بالضبط):
//   الوشاح (8 صور)  → يرفرف بهدوء نفس السلاش
//   الجسم            → ثابت
//   الزئبق (36 صورة) → الكرتين يتحركون مثل الزئبق + فقاعة تطلع وتطير وتختفي
//   الراس            → ثابت
//   العيون           → ترمش
//   النجمة           → تنبض
//   اليدين           → فوق النجمة
//   اللمعات          → تلمع مع النجمة
struct RewardAnimatedMascot: View {
    @State private var capeFrame = 1
    @State private var flameFrame = 1
    @State private var eyesClosed = false
    @State private var pulse = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // مركز النجمة واللمعات داخل الصورة (عشان تنبض حول نفسها)
    private let starCentre = UnitPoint(x: 0.675, y: 0.549)
    private let sparkleCentre = UnitPoint(x: 0.883, y: 0.458)

    var body: some View {
        ZStack {
            // الوشاح (ورا الجسم)
            ForEach(1...8, id: \.self) { frame in
                Image("Reward Cape \(frame)")
                    .resizable().scaledToFit()
                    .opacity(capeFrame == frame ? 1 : 0)
            }
            // الجسم
            Image("Reward Body")
                .resizable().scaledToFit()
            // الزئبق اللي فوق الراس
            ForEach(1...36, id: \.self) { frame in
                Image("Reward Flame \(frame)")
                    .resizable().scaledToFit()
                    .opacity(flameFrame == frame ? 1 : 0)
            }
            // الراس (ثابت)
            Image("Reward Head")
                .resizable().scaledToFit()
            // العيون
            Image("Reward Eyes Open")
                .resizable().scaledToFit()
                .opacity(eyesClosed ? 0 : 1)
            Image("Reward Eyes Closed")
                .resizable().scaledToFit()
                .opacity(eyesClosed ? 1 : 0)
            // النجمة تنبض
            Image("Reward Star")
                .resizable().scaledToFit()
                .scaleEffect(pulse ? 1.07 : 1, anchor: starCentre)
            // اليدين فوق النجمة
            Image("Reward Hands")
                .resizable().scaledToFit()
            // اللمعات تلمع مع النجمة
            Image("Reward Sparkles")
                .resizable().scaledToFit()
                .scaleEffect(pulse ? 1.08 : 0.92, anchor: sparkleCentre)
                .opacity(pulse ? 1 : 0.45)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .task { await flameLoop() }
        .task { await capeLoop() }
        .task { await blinkLoop() }
    }

    /// الزئبق: نفس سرعة السلاش
    private func flameLoop() async {
        guard !reduceMotion else { return }
        while !Task.isCancelled {
            flameFrame = flameFrame % 36 + 1
            try? await Task.sleep(for: .seconds(0.08))
        }
    }

    /// الوشاح يرفرف بهدوء: نفس سرعة السلاش
    private func capeLoop() async {
        guard !reduceMotion else { return }
        while !Task.isCancelled {
            capeFrame = capeFrame % 8 + 1
            try? await Task.sleep(for: .seconds(0.16))
        }
    }

    /// رمشة كل كم ثانية
    private func blinkLoop() async {
        guard !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(2.6))
            eyesClosed = true
            try? await Task.sleep(for: .seconds(0.14))
            eyesClosed = false
        }
    }
}


// ============================================================
// المعاينة (Preview)
// ============================================================
// هذا الجزء يعرض الصفحة في Xcode بدون تشغيل التطبيق
// والأرقام هنا للتجربة فقط، تقدرين تغيرينها وتشوفين النتيجة فوراً
#Preview {
    RewardPopupView(
        xp: 10,
        coins: 350,
        stars: 30,
        tip: "Try looking at the object from a different place, like home, school or outdoors .",
        onDone: { print("Done pressed") }   // يطبع في الـ Console عند الضغط
    )
}
