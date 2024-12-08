import UIKit

enum AppTheme {
    static let primary = UIColor(hex: 0xFA433D)    // 主色调 - 鲜红色
    static let secondary = UIColor(hex: 0xF9443D)  // 次要色调 - 明亮的红色
    static let light = UIColor(hex: 0xFB443E)      // 浅色调 - 浅红色
    static let dark = UIColor(hex: 0x961E20)       // 深色调 - 深红色
    static let wine = UIColor(hex: 0x971F20)       // 强调色 - 酒红色
    
    struct Button {
        static let background = primary
        static let selectedBackground = dark
        static let tint = UIColor.white
    }
    
    struct Navigation {
        static let tint = primary
        static let barTint = UIColor.systemBackground
    }
    
    struct TabBar {
        static let tint = primary
        static let unselectedTint = UIColor.secondaryLabel
    }
    
    struct Text {
        static let title = UIColor.label
        static let subtitle = UIColor.secondaryLabel
        static let accent = primary
    }
    
    struct Cell {
        static let background = UIColor.systemBackground
        static let selectedBackground = UIColor.secondarySystemBackground
        static let highlight = primary.withAlphaComponent(0.1)
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hex & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(hex & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
} 