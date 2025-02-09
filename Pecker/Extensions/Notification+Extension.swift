import Foundation

extension Notification.Name {
    static let themeChanged = Notification.Name("ThemeChanged")
    static let languageChanged = Notification.Name("LanguageChanged")
    static let fontSizeChanged = Notification.Name("FontSizeChanged")
    static let sortOrderChanged = Notification.Name("SortOrderChanged")
    static let startAutoRefresh = Notification.Name("StartAutoRefresh")
    static let stopAutoRefresh = Notification.Name("StopAutoRefresh")
    static let startICloudSync = Notification.Name("StartICloudSync")
    static let stopICloudSync = Notification.Name("StopICloudSync")
} 