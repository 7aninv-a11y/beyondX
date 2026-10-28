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

    // ---------- الألوان من Sketch ----------
    let background = Color(hex: "FBF8ED")   // خلفية الصفحة
    let yellowBox  = Color(hex: "FFF4CB")   // لون الصندوق
    let borderGray = Color(hex: "979797")   // لون الحدود
    let textBlack  = Color(hex: "060606")   // لون النصوص

    // ---------- شكل الصفحة ----------
    var body: some View {

        // ZStack: يحط العناصر فوق بعض
        // الخلفية تحت، والمحتوى فوقها
        ZStack {

            // لون الخلفية يغطي الشاشة كلها
            // ignoresSafeArea: يمدد اللون تحت الساعة وتحت الخط السفلي
            background.ignoresSafeArea()

            // VStack: يرتب العناصر عمودياً، واحد تحت الثاني
            // spacing: 0 يعني ما نبي مسافات تلقائية، نتحكم فيها بأنفسنا
            VStack(spacing: 0) {

                // مسافة فوق العنوان (مكان شارة النجوم اللي حذفناها)
                Spacer().frame(height: 91)

                // ----------------------------------------
                // أ) العنوان الكبير
                // ----------------------------------------
                Text("AWESOME !")
                    .font(.system(size: 46, weight: .black))   // black = أثقل وزن للخط
                    .foregroundColor(textBlack)

                // ----------------------------------------
                // ب) صورة الروبوت
                // ----------------------------------------
                Image("mascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 240)  // نفس قياسها في Sketch
                    .padding(.top, 12)

                // ----------------------------------------
                // ج) نص النجوم اللي جمعها + صورة النجمة
                // ----------------------------------------
                HStack(spacing: 6) {
                    Text("You earned: +\(stars)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(textBlack)

                    Image("goldenStar")          // صورة النجمة في Assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                }
                .padding(.top, 24)

                // ----------------------------------------
                // د) صندوق النصيحة
                // ----------------------------------------
                tipBox
                    .padding(.top, 24)

                // Spacer بدون قياس: ياخذ كل المساحة الفاضية
                // وبهذا ينزل الزر لتحت الشاشة
                Spacer()

                // ----------------------------------------
                // هـ) زر Done
                // ----------------------------------------
                // action: الكود اللي ينفذ عند الضغط، وهنا ننفذ onDone
                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .frame(width: 144, height: 50)   // قياس الزر من Sketch
                        .background(Capsule().fill(Color.primaryOrange))   // نفس برتقالي باقي الصفحات
                }
                .padding(.bottom, 30)                    // مسافة من تحت الشاشة
            }
        }
    }

    // ============================================================
    // صندوق النصيحة (فصلناه لحاله عشان الـ body يكون أوضح)
    // ============================================================
    private var tipBox: some View {

        // alignment: .top يخلي الأيقونة والنص يبدون من فوق
        HStack(alignment: .top, spacing: 10) {

            // أيقونة اللمبة
            Image("lightbulb")
                .resizable()
                .scaledToFit()
                .frame(width: 45, height: 39)

            // النصوص: "Tip :" ثم نص النصيحة تحتها
            VStack(alignment: .leading, spacing: 4) {   // leading = محاذاة لليسار
                Text("Tip :")
                Text(tip)
            }
            .font(.system(size: 18))
            .foregroundColor(textBlack)

            // يدفع المحتوى لليسار ويخلي الصندوق يملا عرضه
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)                 // مسافة داخلية يمين ويسار
        .padding(.vertical, 18)                   // مسافة داخلية فوق وتحت
        .frame(width: 318, alignment: .leading)   // عرض الصندوق من Sketch

        // الخلفية + الشادو
        .background(
            RoundedRectangle(cornerRadius: 25)    // زوايا دائرية 25
                .fill(yellowBox)
                // الشادو من Sketch: أسود 10%، x = 0، y = 4، Blur 8 = radius 4
                .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 4)
        )
        // الحدود الرمادية فوق الصندوق
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(borderGray, lineWidth: 1)
        )
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
