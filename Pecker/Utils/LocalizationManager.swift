import Foundation

enum Language: String {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        }
    }
}

class LocalizationManager {
    static let shared = LocalizationManager()
    
    private let languageKey = "app_language"
    private let defaults = UserDefaults.standard
    
    var currentLanguage: Language {
        get {
            if let languageCode = defaults.string(forKey: languageKey),
               let language = Language(rawValue: languageCode) {
                return language
            }
            return .english
        }
        set {
            defaults.set(newValue.rawValue, forKey: languageKey)
            defaults.synchronize()
            
            // 更新语言设置
            if let languagePath = Bundle.main.path(forResource: newValue.rawValue, ofType: "lproj"),
               let bundle = Bundle(path: languagePath) {
                UserDefaults.standard.set([newValue.rawValue], forKey: "AppleLanguages")
                UserDefaults.standard.synchronize()
                
                // 发送语言更改通知
                NotificationCenter.default.post(name: Notification.Name("LanguageDidChange"), object: nil)
            }
        }
    }
    
    private init() {}
    
    func localizedString(for key: String) -> String {
        let bundle = Bundle.main
        return NSLocalizedString(key, tableName: nil, bundle: bundle, value: "", comment: "")
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
    }
}

// 便捷访问方法
func LocalizedString(_ key: String) -> String {
    return LocalizationManager.shared.localizedString(for: key)
} 