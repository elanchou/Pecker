import Foundation
import RealmSwift

class TodaySummaryManager {
    static let shared = TodaySummaryManager()
    private let defaults = UserDefaults.standard
    
    private struct Constants {
        static let lastUpdateTimeKey = "TodaySummaryLastUpdateTime"
        static let summaryKey = "TodaySummaryContent"
        static let enabledKey = "TodaySummaryEnabled"
        static let updateTimeKey = "TodaySummaryUpdateTime" // 存储为小时，默认10
        static let showFrequencyKey = "TodaySummaryShowFrequency" // 存储为小时，默认24
    }
    
    var isEnabled: Bool {
        get { defaults.bool(forKey: Constants.enabledKey) }
        set { defaults.set(newValue, forKey: Constants.enabledKey) }
    }
    
    var updateTime: Int {
        get { defaults.integer(forKey: Constants.updateTimeKey) }
        set { defaults.set(newValue, forKey: Constants.updateTimeKey) }
    }
    
    var showFrequency: Int {
        get { defaults.integer(forKey: Constants.showFrequencyKey) }
        set { defaults.set(newValue, forKey: Constants.showFrequencyKey) }
    }
    
    private init() {
        // 设置默认值
        if defaults.object(forKey: Constants.enabledKey) == nil {
            defaults.set(true, forKey: Constants.enabledKey)
        }
        if defaults.object(forKey: Constants.updateTimeKey) == nil {
            defaults.set(10, forKey: Constants.updateTimeKey) // 默认10点更新
        }
        if defaults.object(forKey: Constants.showFrequencyKey) == nil {
            defaults.set(24, forKey: Constants.showFrequencyKey) // 默认24小时显示一次
        }
    }
    
    func shouldShowSummary() -> Bool {
        
        return true
        
        guard isEnabled else { return false }
        
        if let lastShowTime = defaults.object(forKey: Constants.lastUpdateTimeKey) as? Date {
            let calendar = Calendar.current
            let now = Date()
            
            // 如果不是同一天，应该显示
            if !calendar.isDate(lastShowTime, inSameDayAs: now) {
                return true
            }
            
            // 如果是同一天，检查时间间隔
            let hours = calendar.dateComponents([.hour], from: lastShowTime, to: now).hour ?? 0
            return hours >= showFrequency
        }
        return true
    }
    
    func shouldUpdateSummary() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        if let lastUpdateTime = defaults.object(forKey: Constants.lastUpdateTimeKey) as? Date {
            // 如果不是同一天且当前时间大于更新时间，需要更新
            if !calendar.isDate(lastUpdateTime, inSameDayAs: now) && hour >= updateTime {
                return true
            }
        } else {
            // 如果从未更新过，且当前时间大于更新时间，需要更新
            return hour >= updateTime
        }
        
        return false
    }
    
    func getSavedSummary() -> String? {
        return defaults.string(forKey: Constants.summaryKey)
    }
    
    func saveSummary(_ summary: String) {
        defaults.set(summary, forKey: Constants.summaryKey)
        defaults.set(Date(), forKey: Constants.lastUpdateTimeKey)
    }
    
    func updateLastShowTime() {
        defaults.set(Date(), forKey: Constants.lastUpdateTimeKey)
    }
} 
