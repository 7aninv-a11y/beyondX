import SwiftUI

/// The animated Beyond robot.
/// Waves with smiling eyes, blinks, cape sways, and a mercury drop
/// buds off the head, floats up and fades away.
/// All images share one canvas, so the layers line up exactly.
struct AnimatedRobot: View {
    /// متى يبدأ يلوّح (بالثواني من أول ما تفتح الصفحة)
    var waveDelay: Double = 0.6

    @State private var wavePose = 1
    @State private var showSparkles = false
    @State private var capeFrame = 1
    @State private var flameFrame = 1
    @State private var eyeState = 0          // 0 open, 1 half, 2 closed, 3 smiling

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Cape (behind the body)
            ForEach(1...8, id: \.self) { frame in
                Image("Robot Cape \(frame)")
                    .resizable().scaledToFit()
                    .opacity(capeFrame == frame ? 1 : 0)
            }
            // Body + waving arm
            ForEach(1...6, id: \.self) { pose in
                Image("Robot Wave \(pose)")
                    .resizable().scaledToFit()
                    .opacity(wavePose == pose ? 1 : 0)
            }
            // Mercury head
            ForEach(1...36, id: \.self) { frame in
                Image("Robot Flame \(frame)")
                    .resizable().scaledToFit()
                    .opacity(flameFrame == frame ? 1 : 0)
            }
            // Eyes
            Image("Robot Eyes Smile")
                .resizable().scaledToFit()
                .opacity(eyeState == 3 ? 1 : 0)
            Image("Robot Eyes Half")
                .resizable().scaledToFit()
                .opacity(eyeState == 1 ? 1 : 0)
            Image("Robot Eyes Closed")
                .resizable().scaledToFit()
                .opacity(eyeState == 2 ? 1 : 0)
            // Sparkles while waving
            Image("Wave Sparkles")
                .resizable().scaledToFit()
                .opacity(showSparkles ? 1 : 0)
        }
        .task { await waveLoop() }
        .task { await capeLoop() }
        .task { await flameLoop() }
    }

    /// Smiles and waves twice, rests calmly with one blink, then repeats.
    private func waveLoop() async {
        guard !reduceMotion else { eyeState = 3; return }
        try? await Task.sleep(for: .seconds(waveDelay))

        let swing = [1, 2, 3, 4, 5, 6, 5, 4, 3, 2]
        let frameTime = 0.06                                  // smaller = faster wave

        while !Task.isCancelled {
            eyeState = 3
            for _ in 0..<2 {
                for pose in swing {
                    wavePose = pose
                    showSparkles = true
                    try? await Task.sleep(for: .seconds(frameTime))
                }
            }
            wavePose = 1
            showSparkles = false
            try? await Task.sleep(for: .seconds(0.4))

            eyeState = 0
            try? await Task.sleep(for: .seconds(1.5))
            for state in [1, 2, 2, 1, 0] {
                eyeState = state
                try? await Task.sleep(for: .seconds(0.04))
            }
            try? await Task.sleep(for: .seconds(1.8))
        }
    }

    /// Cape sways gently.
    private func capeLoop() async {
        guard !reduceMotion else { return }
        while !Task.isCancelled {
            capeFrame = capeFrame % 8 + 1
            try? await Task.sleep(for: .seconds(0.16))       // smaller = faster
        }
    }

    /// Mercury head: a drop buds off, floats up and fades away.
    private func flameLoop() async {
        guard !reduceMotion else { return }
        while !Task.isCancelled {
            flameFrame = flameFrame % 36 + 1
            try? await Task.sleep(for: .seconds(0.08))       // smaller = faster
        }
    }
}

#Preview {
    AnimatedRobot()
        .frame(width: 270, height: 250)
}
