import SwiftUI

extension Color {
    // MARK: - Core Palette
    static let aappBackground = Color(red: 251/255, green: 248/255, blue: 237/255) // #FBF8ED
    static let primaryOrange = Color(hex: "E8723B")       // #E8723B
    static let logoOrange = Color(hex: "FF792E")          // #FF792E
    static let nearBlack = Color(hex: "161616")           // #161616
    
    // MARK: - Cards & Badges
    static let lockedOverlay = Color(hex: "919191").opacity(0.706) // 71% Opacity
    static let lockedBorder = Color(hex: "979797")
    static let completedBadgeBg = Color(hex: "F1F2F9").opacity(0.90)
    static let badgeBorder = Color(hex: "EBEBEB")
    static let lockedBadgeBg = Color(hex: "7A7575")
    
    // MARK: - Text
    static let textPrimary = Color(hex: "060606")
    static let textSecondary = Color(hex: "373737")
    static let textSplashTagline = Color(hex: "625F5F")
    static let textSubtitle = Color(hex: "888585")

    // ألوان صفحة الـ Pause
    static let pauseCard = Color(hex: "EBEBEB")
    static let pauseButtonGray = Color(hex: "DADADA")
    static let pauseSubtitle = Color(hex: "8E8E93")
}

// MARK: - Hex Helper Extension
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}


// MARK: - Pause Page
// الاستخدام في أي صفحة:
//   @State private var showPause = false
//   .pausePage(isPresented: $showPause, onPause: { dismiss() })
//
// ولو تبين عبارة خاصة لليفل:
//   .pausePage(isPresented: $showPause, message: PauseMessages.level1, onPause: { dismiss() })
//
// onContinue و onBack اختياريين:
//   - Continue إذا ما كتبتيه: يسكّر الـ Pause بس
//   - زر الرجوع إذا ما كتبتيه: يسوي نفس زر pause
extension View {
    func pausePage(isPresented: Binding<Bool>,
                   message: String = "Do you want to pause your creative journey?",   // NEW: عبارة كل ليفل
                   onPause: @escaping () -> Void,
                   onContinue: @escaping () -> Void = {},
                   onBack: (() -> Void)? = nil) -> some View {
        self
            .blur(radius: isPresented.wrappedValue ? 8 : 0)   // الصفحة اللي ورا تصير ضبابية
            .overlay {
            if isPresented.wrappedValue {
                PausePageView(
                    message: message,                          // NEW
                    onBack: {
                        isPresented.wrappedValue = false
                        (onBack ?? onPause)()
                    },
                    onPause: {
                        isPresented.wrappedValue = false
                        onPause()
                    },
                    onContinue: {
                        isPresented.wrappedValue = false
                        onContinue()
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isPresented.wrappedValue)
    }
}

struct PausePageView: View {

    var message: String = "Do you want to pause your creative journey?"   // NEW: العبارة تحت "Need a break ?"

    var onBack: () -> Void         // زر الرجوع (فوق يسار)
    var onPause: () -> Void        // زر pause: يطلع من الليفل (التقدم محفوظ)
    var onContinue: () -> Void     // زر Continue: يكمل اللعب

    var body: some View {
        ZStack {
            // خلفية شفافة، الصفحة اللي ورا تبان
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // زر الرجوع
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.25)))
                        .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
                }
                .padding(.leading, 42)
                .padding(.top, 13)

                Spacer().frame(height: 121)

                // الروبوت + البطاقة (الروبوت يطل من ورا البطاقة)
                VStack(alignment: .leading, spacing: -23) {
                    Image("pauseMascot")             // "Cute Mint-Caped Robot Mascot" من Sketch
                        .resizable()
                        .scaledToFit()
                        .frame(width: 204, height: 186)
                        .padding(.leading, 36)

                    pauseCard
                }
                .padding(.horizontal, 51)

                Spacer()
            }
        }
    }

    private var pauseCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Need a break ?")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.textPrimary)

            Text(message)                                  // CHANGED: كانت "Progress saved..."
                .font(.system(size: 17))
                .fixedSize(horizontal: false, vertical: true)   // ينزل سطر ثاني لو طويل
                .foregroundColor(.pauseSubtitle)
                .padding(.top, 14)

            HStack(spacing: 10) {
                Button(action: onPause) {
                    Text("pause")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Capsule().fill(Color.pauseButtonGray))
                }

                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Capsule().fill(Color.primaryOrange))
                }
            }
            .padding(.top, 22)
        }
        .padding(.horizontal, 14)
        .padding(.top, 22)
        .padding(.bottom, 22)
        .padding(.leading, 8)
        .frame(maxWidth: .infinity, minHeight: 171, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 34)
                .fill(Color.pauseCard)
                .shadow(color: .black.opacity(0.18), radius: 30, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 34)
                .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
        )
    }
}
