import SwiftUI

struct ContentView: View {
    // Intro sequence
    @State private var showName = false        // "Beyond ✕" fades in at the centre
    @State private var nameSettled = false     // then glides up to its place
    @State private var showTagline = false
    @State private var showRobot = false
    @State private var showButton = false

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Spacer().frame(height: 70)

                    // 1. Header Lockup — "Beyond ✕" with the tagline centered under it (Sketch)
                    VStack(alignment: .center, spacing: 12) {
                        HStack(alignment: .center, spacing: 8) {
                            Text("Beyond")
                                .font(.system(size: 56, weight: .bold))
                                .foregroundColor(Color(hex: "161616"))

                            BeyondXMark(width: 41)
                                .offset(y: 5)
                        }

                        Text("Your Mind, No Limits.")
                            .font(.custom("Arial-BoldMT", size: 20))       // Sketch: Arial Bold 20
                            .foregroundColor(Color(hex: "625F5F"))
                            .opacity(showTagline ? 1 : 0)
                            .offset(y: showTagline ? 0 : 8)
                    }
                    .compositingGroup()
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 4)   // Sketch: #000 10%, y 4, blur 8
                    .frame(maxWidth: .infinity, alignment: .center)
                    // starts in the middle of the screen, a bit bigger, then moves up
                    .scaleEffect(nameSettled ? 1 : 1.15)
                    .offset(y: nameSettled ? 0 : geo.size.height / 2 - 105)
                    .opacity(showName ? 1 : 0)

                    Spacer().frame(height: 86)

                    // 2. Robot Mascot (animated) — Sketch: الروبوت صار أكبر (282 → 314)
                    // يبدأ يلوّح أول ما يطلع (الروبوت يطلع بعد 1.6 ثانية من فتح الصفحة)
                    AnimatedRobot(waveDelay: 1.7)
                        .frame(width: 272, height: 248)
                        .compositingGroup()
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 4)   // Sketch: #000 10%, y 4, blur 8
                        .scaleEffect(showRobot ? 1 : 0.6)
                        .opacity(showRobot ? 1 : 0)

                    Spacer()

                    // 3. Primary CTA Button
                    NavigationLink(destination: JourneyView()) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 15, weight: .regular))
                            Text("Let’s Get Creative!")
                                .font(.system(size: 17, weight: .regular))
                        }
                        .foregroundColor(.white)
                        .frame(width: 236, height: 50)
                        .background(Color(hex: "E8723B"), in: Capsule())
                        .compositingGroup()
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 4)   // Sketch: #000 10%, y 4, blur 8
                    }
                    .padding(.bottom, 112)
                    .opacity(showButton ? 1 : 0)
                    .offset(y: showButton ? 0 : 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color("AppBackground").ignoresSafeArea())
            .task { await playIntro() }
        }
    }

    private func playIntro() async {
        guard !showName else { return }          // don't replay when coming back

        // 1. name appears in the centre
        withAnimation(.easeOut(duration: 0.5)) { showName = true }
        try? await Task.sleep(for: .seconds(1.1))

        // 2. name glides up to its place
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { nameSettled = true }
        try? await Task.sleep(for: .seconds(0.35))

        // 3. the rest shows up one after another
        withAnimation(.easeOut(duration: 0.4)) { showTagline = true }
        try? await Task.sleep(for: .seconds(0.15))
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { showRobot = true }
        try? await Task.sleep(for: .seconds(0.3))
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) { showButton = true }
    }
}
