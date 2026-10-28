//
//  Levelhelpers.swift
//  beyondX
//
//  Created by SAFIA  on 17/05/1448 AH.
//

import SwiftUI

// =====================================================
// أدوات مشتركة لكل صفحات الليفلات
// =====================================================


// MARK: - 0) التيبات اللي تطلع في صفحة الريوارد

// كل ليفل له تيب خاص فيه، ونستخدمه كذا: LevelTips.level1
enum LevelTips {

    // Level 1: What if…?
    static let level1 = "Don't stop at the first idea! Ask \"and then what?\" to see how one change can transform everyday life."

    // Level 2: This is not a stop sign…
    static let level2 = "Turn it upside down, zoom in, or squint! A simple shape can become anything when you stop seeing what it's supposed to be."
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
