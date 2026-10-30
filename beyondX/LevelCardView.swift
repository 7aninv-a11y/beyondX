import SwiftUI

enum LevelState {
    case active
    case completed
    case locked
}

struct LevelCardView: View {
    let levelNumber: String
    let title: String
    let state: LevelState
    let mascotImageName: String

    // NEW: إعدادات الأنميشن (كلها اختيارية، ولو ما انرسلت يشتغل الكرت عادي)
    var showActiveBorder: Bool = true            // البوردر البرتقالي ظاهر؟ (اللمعة أول ما تفتح الصفحة)
    var isUnlocking: Bool = false                // الكرت في نص فتح القفل (لسا رمادي)
    var lockIsOpen: Bool = false                 // القفل انفتح 🔓

    let action: () -> Void

    // NEW: أنميشن الكرت (شكل بس، ما يغير أي منطق)
    @State private var arrowBounce = false       // نطة زر السهم
    @State private var isPressed = false         // الكرت ينضغط تحت الإصبع
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // الكرت يبين مقفول (رمادي + قفل): لو مقفول، أو لسا في نص فتح القفل
    private var showsLockedLook: Bool {
        state == .locked || isUnlocking
    }

    // وقت الضغط الحد يصير برتقالي (لأي كرت مو مقفول)
    private var pressedBorder: Bool {
        isPressed && state != .locked
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Main Card Surface
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color.white)
                .frame(width: 337, height: 140)

            // 1. Left Text Stack (Exact vertical alignment matching Sketch)
            VStack(alignment: .leading, spacing: 0) {
                Text("Level \(levelNumber)")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color(hex: "373737"))
                    .frame(height: 14, alignment: .leading)

                Text("0\(levelNumber)")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(Color(hex: "060606"))
                    .frame(height: 50, alignment: .leading)

                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "060606"))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(width: 125, alignment: .leading)
            }
            .padding(.leading, 26)
            .padding(.top, 18) // Adjusted top padding to raise text stack

            // 2. Robot Mascot (Positioned centered in gap, matching Sketch)
            HStack {
                Spacer()
                Image(mascotImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                Spacer()
            }
            .padding(.leading, 120) // Offsets mascot past text column
            .padding(.trailing, 65)  // Keeps spacing before action badge

            // 3. Locked State Dark Overlay (يتلاشى بالتدريج لما ينفتح القفل)
            // دايماً موجود، بس شفافيته تتغير، عشان التلاشي يطلع ناعم
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color(hex: "919191").opacity(0.706))
                .frame(width: 337, height: 140)
                .opacity(showsLockedLook ? 1 : 0)
                .allowsHitTesting(false)

            // 4. Action Badge (44x44 Circle aligned right)
            HStack {
                Spacer()
                badge
                    .padding(.trailing, 15)
            }
        }
        .frame(width: 337, height: 140)
        // Outer Card Border (رمادي، ويصير برتقالي وقت الضغط)
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .strokeBorder(pressedBorder ? Color("AccentOrange") : Color(hex: "979797"),
                              lineWidth: pressedBorder ? 2.5 : 1.0)
        )
        // NEW: البوردر البرتقالي حق الليفل المفتوح (يطلع بنعومة بعد ما ينفتح القفل)
        .overlay { activeBorder }
        .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 4)
        // الكرت يصغر شوي وهو مضغوط
        .scaleEffect(isPressed ? 0.97 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        // Tap anywhere on the card (not when locked)
        .contentShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .onTapGesture {
            if state != .locked { action() }
        }
        // نعرف إن الإصبع على الكرت (يشتغل مع الضغط العادي، ما يوقفه)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if state != .locked && !isPressed { isPressed = true }
                }
                .onEnded { _ in isPressed = false }
        )
        // نطة السهم: أول ما تفتح الصفحة، أو بعد ما ينفتح القفل
        .task(id: "\(state)-\(isUnlocking)") { await playArrowBounce() }
    }

    // MARK: - البوردر البرتقالي

    @ViewBuilder
    private var activeBorder: some View {
        if state == .active && !isUnlocking {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .strokeBorder(Color("AccentOrange"), lineWidth: 2.5)
                .opacity(showActiveBorder ? 1 : 0)
                .transition(.opacity)
        }
    }

    // MARK: - الزر اللي يمين (قفل / سهم / صح)

    @ViewBuilder
    private var badge: some View {
        if showsLockedLook {
            // القفل: يهتز ويتحول لقفل مفتوح
            ZStack {
                Circle()
                    .fill(Color(hex: "7A7575"))
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color(hex: "EBEBEB"), lineWidth: 0.5))

                Image(systemName: lockIsOpen ? "lock.open.fill" : "lock.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(hex: "1A1A1A"))
                    .contentTransition(.symbolEffect(.replace))
            }
            .keyframeAnimator(initialValue: LockWiggle(), trigger: lockIsOpen) { content, wiggle in
                content.rotationEffect(.degrees(wiggle.angle))
            } keyframes: { _ in
                KeyframeTrack(\.angle) {
                    CubicKeyframe(-14, duration: 0.12)       // هزة أهدى شوي
                    CubicKeyframe(12, duration: 0.15)
                    CubicKeyframe(-8, duration: 0.15)
                    CubicKeyframe(0, duration: 0.18)
                }
            }
            .transition(.scale(scale: 0.6).combined(with: .opacity))
        } else if state == .active {
            Button(action: action) {
                CircleBadge(bgColor: Color("AccentOrange"), iconName: "arrow.right", iconColor: Color(hex: "1A1A1A"))
                    .scaleEffect(arrowBounce ? 1.15 : 1)     // نطة صغيرة
            }
            .transition(.scale(scale: 0.6).combined(with: .opacity))
        } else {
            CircleBadge(bgColor: Color(hex: "F1F2F9").opacity(0.90), iconName: "checkmark", iconColor: Color(hex: "1A1A1A"))
                .transition(.scale(scale: 0.6).combined(with: .opacity))
        }
    }

    // MARK: - نطة السهم

    private func playArrowBounce() async {
        guard state == .active, !isUnlocking, !reduceMotion else { return }
        try? await Task.sleep(for: .seconds(1.2))
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { arrowBounce = true }
        try? await Task.sleep(for: .seconds(0.2))
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { arrowBounce = false }
    }
}

// زاوية هزة القفل
private struct LockWiggle {
    var angle: Double = 0
}

// Custom Badge with Bolder Icons
struct CircleBadge: View {
    let bgColor: Color
    let iconName: String
    let iconColor: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(bgColor)
                .frame(width: 44, height: 44)
                .overlay(Circle().stroke(Color(hex: "EBEBEB"), lineWidth: 0.5))
            
            Image(systemName: iconName)
                .font(.system(size: 17, weight: .bold)) // Bolder weight to match Sketch
                .foregroundColor(iconColor)
        }
    }
}
