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
