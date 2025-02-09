import Foundation
import Kingfisher
import UIKit

class SettingsManager {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        static let theme = "app_theme"
        static let language = "app_language"
        static let autoRefresh = "auto_refresh"
        static let iCloudSync = "icloud_sync"
        static let fontSize = "font_size"
        static let sortOrder = "sort_order"
        static let notificationsEnabled = "notifications_enabled"
        static let lastRefreshDate = "last_refresh_date"
    }
    
    // MARK: - Theme
    enum Theme: String {
        case system
        case light
        case dark
        
        var uiInterfaceStyle: UIUserInterfaceStyle {
            switch self {
            case .system: return .unspecified
            case .light: return .light
            case .dark: return .dark
            }
        }
    }
    
    var currentTheme: Theme {
        get {
            if let themeString = defaults.string(forKey: Keys.theme),
               let theme = Theme(rawValue: themeString) {
                return theme
            }
            return .system
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.theme)
            applyTheme(newValue)
        }
    }
    
    var languageCode: String {
        get {
            if let languageCode = defaults.string(forKey: Keys.language) {
                return languageCode
            }
            return "en"
        }
        set {
            defaults.set(newValue, forKey: Keys.language)
            applyLanguageSettings()
        }
    }
    
    // MARK: - Auto Refresh
    var isAutoRefreshEnabled: Bool {
        get { defaults.bool(forKey: Keys.autoRefresh) }
        set { 
            defaults.set(newValue, forKey: Keys.autoRefresh)
            if newValue {
                setupAutoRefresh()
            } else {
                stopAutoRefresh()
            }
        }
    }
    
    // MARK: - iCloud Sync
    var isICloudSyncEnabled: Bool {
        get { defaults.bool(forKey: Keys.iCloudSync) }
        set { 
            defaults.set(newValue, forKey: Keys.iCloudSync)
            if newValue {
                startICloudSync()
            } else {
                stopICloudSync()
            }
        }
    }
    
    // MARK: - Font Size
    var fontSize: CGFloat {
        get { CGFloat(defaults.float(forKey: Keys.fontSize)) as CGFloat }
        set { defaults.set(Float(newValue), forKey: Keys.fontSize) }
    }
    
    // MARK: - Sort Order
    enum SortOrder: String {
        case dateDesc = "date_desc"
        case dateAsc = "date_asc"
        case titleAsc = "title_asc"
        case unreadFirst = "unread_first"
    }
    
    var sortOrder: SortOrder {
        get {
            if let orderString = defaults.string(forKey: Keys.sortOrder),
               let order = SortOrder(rawValue: orderString) {
                return order
            }
            return .dateDesc
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.sortOrder) }
    }
    
    // MARK: - Notifications
    var areNotificationsEnabled: Bool {
        get { defaults.bool(forKey: Keys.notificationsEnabled) }
        set {
            defaults.set(newValue, forKey: Keys.notificationsEnabled)
            if newValue {
                requestNotificationPermission()
            }
        }
    }
    
    // MARK: - Methods
    private func applyTheme(_ theme: Theme) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = theme.uiInterfaceStyle
            }
        }
    }
    
    private func applyLanguageSettings() {
        if let languagePath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: languagePath) {
            UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
    }
    
    private func setupAutoRefresh() {
        // 设置自动刷新的时间间隔和逻辑
        NotificationCenter.default.post(name: NSNotification.Name("StartAutoRefresh"), object: nil)
    }
    
    private func stopAutoRefresh() {
        NotificationCenter.default.post(name: NSNotification.Name("StopAutoRefresh"), object: nil)
    }
    
    private func startICloudSync() {
        // 实现 iCloud 同步逻辑
        NotificationCenter.default.post(name: NSNotification.Name("StartICloudSync"), object: nil)
    }
    
    private func stopICloudSync() {
        NotificationCenter.default.post(name: NSNotification.Name("StopICloudSync"), object: nil)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    // MARK: - Cache Management
    func clearCache() async throws {
        // 清除图片缓存
        ImageCache.default.clearMemoryCache()
        await ImageCache.default.clearDiskCache()
        
        // 清除 Realm 缓存
        try await RealmManager.shared.clearCache()
        
        // 记录最后清理时间
        defaults.set(Date(), forKey: Keys.lastRefreshDate)
    }
    
    // MARK: - Export/Import
    func exportData() async throws -> URL {
        // 实现数据导出逻辑
        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent("pecker_backup.json")
        // TODO: 实现导出逻辑
        return exportURL
    }
    
    func importData(from url: URL) async throws {
        // 实现数据导入逻辑
        // TODO: 实现导入逻辑
    }
} 
