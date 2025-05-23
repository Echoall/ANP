import SwiftUI

extension Color {
    #if os(iOS)
    static let taskBackground = Color(UIColor.systemBackground)
    static let taskGroupBackground = Color(UIColor.secondarySystemBackground)
    static let taskText = Color(UIColor.label)
    static let taskSecondaryText = Color(UIColor.secondaryLabel)
    static let taskTertiaryText = Color(UIColor.tertiaryLabel)
    #else
    static let taskBackground = Color(.textBackgroundColor)
    static let taskGroupBackground = Color(.windowBackgroundColor)
    static let taskText = Color(.labelColor)
    static let taskSecondaryText = Color(.secondaryLabelColor)
    static let taskTertiaryText = Color(.tertiaryLabelColor)
    #endif
    
    static let taskAccent = Color.blue
    
    // 从十六进制字符串转换为Color - 增加了跨平台兼容性
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // 新增颜色方法，用于在项目中替代直接使用Color(hex:)
    static func fromHex(_ hex: String) -> Color {
        return Color(hex: hex)
    }
} 