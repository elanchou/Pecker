import Foundation
import RealmSwift

func formatDate(_ date: Date, needTime: Bool = true) -> String {
    let formatter = DateFormatter()
    let currentLanguage = LocalizationManager.shared.currentLanguage

    // Set locale based on current language
    switch currentLanguage {
    case .english:
        formatter.locale = Locale(identifier: "en_US")
    case .simplifiedChinese:
        formatter.locale = Locale(identifier: "zh_CN")
    }

    let calendar = Calendar.current

    if calendar.isDateInToday(date) {
        formatter.dateFormat = "HH:mm"
        let timeString = needTime ? formatter.string(from: date) : ""
        return currentLanguage == .english ? "Today \(timeString)" : "今天 \(timeString)"
    } else if calendar.isDateInYesterday(date) {
        formatter.dateFormat = "HH:mm"
        let timeString = needTime ? formatter.string(from: date) : ""
        return currentLanguage == .english ? "Yesterday \(timeString)" : "昨天 \(timeString)"
    } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
        formatter.dateFormat = needTime ? "EEEE HH:mm" : "EEEE"
        return formatter.string(from: date)
    } else {
        formatter.dateFormat = needTime ? "MMM dd HH:mm" : "MMM dd"
        return formatter.string(from: date)
    }
}


func groupContentsByDate(_ contents: [Content]) -> [(Date, [Content])] {
    let calendar = Calendar.current
    
    let grouped = Dictionary(grouping: contents) { content in
        calendar.startOfDay(for: content.publishDate)
    }
    
    return grouped.sorted { $0.key > $1.key }
}

func filterContents(_ contents: [Content], searchText: String) -> [Content] {
    if searchText.isEmpty {
        return contents.sorted { $0.publishDate > $1.publishDate }
    }
    return contents
        .filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        .sorted { $0.publishDate > $1.publishDate }
} 
