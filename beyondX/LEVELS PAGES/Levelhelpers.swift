import SwiftUI

// =====================================================
// أدوات مشتركة لكل صفحات الليفلات
// =====================================================


// MARK: - 0) التيبات اللي تطلع في صفحة الريوارد

// كل ليفل له تيب خاص فيه، ونستخدمه كذا: LevelTips.level1
enum LevelTips {

    // Level 1: What if…? (الطيران)
    static let level1 = "Amazing start! Your imagination is your superpower. Keep it flying!"

    // Level 2: This is not a stop sign… (الأشكال)
    static let level2 = "You turned something ordinary into something new. That's real creativity!"

    // Level 3: يطلع في صفحة الاحتفال (مو الريوارد)
    static let level3 = "You did it! You're a creative thinker. Keep surprising the world with your ideas!"
}
// MARK: - 0.1) العبارات اللي تطلع في صفحة الـ Pause

// كل ليفل له عبارة خاصة، ونستخدمها كذا: PauseMessages.level1
enum PauseMessages {

    // Level 1: What if…? (الطيران)
    static let level1 = "Your ideas are still flying… stop now?"

    // Level 2: This is not a stop sign… (الأشكال)
    static let level2 = "Your masterpiece is still taking shape… stop now?"

    // Level 3: Think beyond the object (الكوب)
    static let level3 = "This cup still has hidden uses… stop now?"
}


// MARK: - 1) تشييك التكرار

// دالة تشتغل على أي مصفوفة نصوص، مثل: ideas.isAlreadyWritten("...")
extension Array where Element == String {

    /// ترجع true إذا الفكرة موجودة من قبل في المصفوفة
    /// نحوّل الحروف كلها small عشان "Fly" و "fly" تنحسب نفس الفكرة
    func isAlreadyWritten(_ newIdea: String) -> Bool {
        let newIdeaSmall = newIdea.lowercased()

        for oldIdea in self {
            if oldIdea.lowercased() == newIdeaSmall {
                return true     // لقينا نفس الفكرة → مكررة
            }
        }
        return false            // ما لقيناها → فكرة جديدة
    }
}


// MARK: - 2) معرفة مكان أي عنصر في الشاشة

extension View {

    /// تحفظ مكان العنصر في الشاشة (نحتاجه عشان نعرف من وين تطير النجمة ووين توصل)
    /// مهم: لازم الصفحة يكون فيها .coordinateSpace(.named("screen"))
    func readFrame(_ action: @escaping (CGRect) -> Void) -> some View {
        onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named("screen"))
        } action: { newFrame in
            action(newFrame)
        }
    }
}


// MARK: - 3) النجمة الطايرة

struct FlyingStarModifier: ViewModifier {
    @Binding var isFlying: Bool     // لما نخليه true النجمة تطير
    let from: CGPoint               // مكان البداية
    let to: CGPoint                 // مكان النهاية
    let onArrive: () -> Void        // وش يصير لما توصل

    // false = النجمة في البداية، true = النجمة وصلت
    @State private var arrived = false

    func body(content: Content) -> some View {
        content
            // نرسم النجمة فوق الصفحة
            .overlay {
                if isFlying {
                    Image(systemName: "star.fill")
                        .font(.system(size: arrived ? 18 : 44))          // تصغر وهي تطير
                        .foregroundStyle(Color(hex: "F5C518"))
                        .shadow(color: .orange.opacity(0.4), radius: 8)
                        .position(arrived ? to : from)                   // تنتقل من البداية للنهاية
                        .allowsHitTesting(false)                         // ما تمنع الضغط على الأزرار
                }
            }
            // أول ما isFlying يصير true نبدأ الحركة
            .onChange(of: isFlying) { _, flying in
                guard flying else { return }

                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.7)) {
                        arrived = true                 // ← هنا تطير
                    } completion: {
                        isFlying = false               // نخفيها
                        arrived = false                // نرجعها للبداية للمرة الجاية
                        onArrive()                     // ننفذ اللي بعد الوصول
                    }
                }
            }
    }
}

extension View {

    /// طريقة الاستخدام في أي ليفل:
    /// .flyingStar(isFlying: $isStarFlying, from: نقطة البداية, to: نقطة النهاية) {
    ///     earnedStars += 10
    /// }
    func flyingStar(isFlying: Binding<Bool>,
                    from: CGPoint,
                    to: CGPoint,
                    onArrive: @escaping () -> Void) -> some View {
        modifier(FlyingStarModifier(isFlying: isFlying, from: from, to: to, onArrive: onArrive))
    }
}
