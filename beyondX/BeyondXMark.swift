import SwiftUI

/// The orange "X" from the Beyond logo, drawn as a vector (same path as in Sketch),
/// so it is always sharp and sits exactly where the design puts it.
struct BeyondXShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Original artwork box: 47.954 x 50.126
        let sx = rect.width / 47.954
        let sy = rect.height / 50.126
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }
        var path = Path()
        path.move(to: p(2.2628, 2.6657))
        path.addCurve(to: p(13.8280, 3.3738), control1: p(5.7245, -1.1107), control2: p(9.5795, -0.8747))
        path.addLine(to: p(23.9770, 13.9949))
        path.addLine(to: p(34.1261, 3.3738))
        path.addCurve(to: p(45.6913, 2.6657), control1: p(38.3746, -0.8747), control2: p(42.2296, -1.1107))
        path.addCurve(to: p(44.7472, 13.7589), control1: p(48.9957, 6.1274), control2: p(48.6810, 9.8251))
        path.addLine(to: p(32.9460, 25.0881))
        path.addLine(to: p(44.7472, 36.8893))
        path.addCurve(to: p(45.4553, 47.7464), control1: p(48.6810, 40.8230), control2: p(48.9170, 44.4421))
        path.addCurve(to: p(34.1261, 46.8023), control1: p(41.8363, 51.2081), control2: p(38.0599, 50.8934))
        path.addLine(to: p(23.9770, 36.4172))
        path.addLine(to: p(13.8280, 46.8023))
        path.addCurve(to: p(2.4988, 47.7464), control1: p(9.8942, 50.8934), control2: p(6.1178, 51.2081))
        path.addCurve(to: p(3.2069, 36.8893), control1: p(-0.9629, 44.4421), control2: p(-0.7269, 40.8230))
        path.addLine(to: p(15.0081, 25.0881))
        path.addLine(to: p(3.2069, 13.7589))
        path.addCurve(to: p(2.2628, 2.6657), control1: p(-0.7269, 9.8251), control2: p(-1.0416, 6.1274))
        path.closeSubpath()
        return path
    }
}

/// Animated X: pops in with a spin, then every few seconds does a quick
/// bouncy quarter-turn. An X turned 90° looks the same, so the loop is seamless.
struct BeyondXMark: View {
    var width: CGFloat = 48
    @State private var appeared = false
    @State private var turns: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        BeyondXShape()
            .fill(Color(hex: "FF792E"))
            .frame(width: width, height: width * 50.126 / 47.954)
            .rotationEffect(.degrees(turns * 90 + (appeared ? 0 : -180)))
            .scaleEffect(appeared ? 1 : 0.2)
            .opacity(appeared ? 1 : 0)
            .task {
                if reduceMotion { appeared = true; return }
                try? await Task.sleep(for: .seconds(0.3))
                withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) {
                    appeared = true
                }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(3.5))      // time between spins
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.5)) {
                        turns += 1
                    }
                }
            }
    }
}

#Preview {
    BeyondXMark().padding()
}
