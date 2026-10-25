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
    let action: () -> Void
    
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
            
            // 3. Locked State Dark Overlay
            if state == .locked {
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(Color(hex: "919191").opacity(0.706))
                    .frame(width: 337, height: 140)
            }
            
            // 4. Action Badge (44x44 Circle aligned right)
            HStack {
                Spacer()
                Group {
                    switch state {
                    case .active:
                        Button(action: action) {
                            CircleBadge(bgColor: Color("AccentOrange"), iconName: "arrow.right", iconColor: Color(hex: "1A1A1A"))
                        }
                    case .completed:
                        CircleBadge(bgColor: Color(hex: "F1F2F9").opacity(0.90), iconName: "checkmark", iconColor: Color(hex: "1A1A1A"))
                    case .locked:
                        CircleBadge(bgColor: Color(hex: "7A7575"), iconName: "lock.fill", iconColor: Color(hex: "1A1A1A"))
                    }
                }
                .padding(.trailing, 15)
            }
        }
        .frame(width: 337, height: 140)
        // Outer Card Border
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .strokeBorder(state == .active ? Color("AccentOrange") : Color(hex: "979797"), lineWidth: state == .active ? 2.5 : 1.0)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 4)
    }
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
