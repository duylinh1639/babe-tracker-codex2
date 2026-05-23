import SwiftUI
import UIKit

enum AppTheme {
    static let cornerRadius: CGFloat = 20
    static let smallRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16

    static func tint(for name: String) -> Color {
        switch name {
        case "sleep": return .sleep
        case "growth": return .growth
        case "diaper": return .diaper
        case "vaccine": return .vaccine
        case "med": return .medicine
        case "alert": return .appAlert
        default: return .appPrimary
        }
    }
}

extension Color {
    static let appPrimary = Color(hex: "7C5CBF")
    static let appBackground = Color(light: Color(hex: "F9F8FF"), dark: Color(hex: "121018"))
    static let cardBackground = Color(light: .white, dark: Color(hex: "1E1B26"))
    static let softBorder = Color.primary.opacity(0.06)
    static let textSecondary = Color(light: Color(hex: "7B6F8A"), dark: Color(hex: "BDB2CF"))

    static let sleep = Color(hex: "5B5BD6")
    static let sleepBackground = Color(light: Color(hex: "F0F4FF"), dark: Color(hex: "20213B"))
    static let growth = Color(hex: "2DBD7E")
    static let growthBackground = Color(light: Color(hex: "F0FFF8"), dark: Color(hex: "152E23"))
    static let diaper = Color(hex: "C47D00")
    static let diaperBackground = Color(light: Color(hex: "FFF8EC"), dark: Color(hex: "332818"))
    static let vaccine = Color(hex: "C47D00")
    static let vaccineBackground = Color(light: Color(hex: "FFFDF0"), dark: Color(hex: "302C16"))
    static let medicine = Color(hex: "1A8A54")
    static let medicineBackground = Color(light: Color(hex: "F0FFF6"), dark: Color(hex: "153024"))
    static let appAlert = Color(hex: "D63B6A")
    static let alertBackground = Color(light: Color(hex: "FFF0F3"), dark: Color(hex: "351824"))

    init(hex: String, opacity: Double = 1) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red: UInt64
        let green: UInt64
        let blue: UInt64

        switch cleaned.count {
        case 3:
            red = ((value >> 8) & 0xF) * 17
            green = ((value >> 4) & 0xF) * 17
            blue = (value & 0xF) * 17
        default:
            red = (value >> 16) & 0xFF
            green = (value >> 8) & 0xFF
            blue = value & 0xFF
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: opacity
        )
    }

    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

extension Font {
    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct CardBackground: ViewModifier {
    var radius: CGFloat = AppTheme.cornerRadius

    func body(content: Content) -> some View {
        content
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.softBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 6)
    }
}

extension View {
    func appCard(radius: CGFloat = AppTheme.cornerRadius) -> some View {
        modifier(CardBackground(radius: radius))
    }
}
