import SwiftUI

extension Color {
    static let appBackground = Color("AppBackground")
    static let accentOrange = Color("AccentOrange")
    static let nearBlack = Color(hex: "161616")
    static let textPrimary = Color(hex: "060606")
    static let textSecondary = Color(hex: "373737")
    static let textSplashTagline = Color(hex: "625F5F")
}

// Hex Helper
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
