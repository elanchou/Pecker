import Foundation
import RealmSwift

func formatDate(_ date: Date, needTime: Bool = true) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    
    if Calendar.current.isDateInToday(date) {
        formatter.dateFormat = "HH:mm"
        return "Today " + (needTime ? formatter.string(from: date) : "")
    } else if Calendar.current.isDateInYesterday(date) {
        formatter.dateFormat = "HH:mm"
        return "Yesterday " + (needTime ? formatter.string(from: date) : "")
    } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
        formatter.dateFormat = needTime ? "EEEE HH:mm" : "EEEE"
        return formatter.string(from: date)
    } else {
        formatter.dateFormat = needTime ? "MM月dd日 HH:mm" : "MM-dd"
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
