import Foundation
import RealmSwift

func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    
    if Calendar.current.isDateInToday(date) {
        formatter.dateFormat = "HH:mm"
        return "今天 " + formatter.string(from: date)
    } else if Calendar.current.isDateInYesterday(date) {
        formatter.dateFormat = "HH:mm"
        return "昨天 " + formatter.string(from: date)
    } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
        formatter.dateFormat = "EEEE HH:mm"
        return formatter.string(from: date)
    } else {
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

func groupArticlesByDate(_ articles: [Article]) -> [(Date, [Article])] {
    let calendar = Calendar.current
    
    let grouped = Dictionary(grouping: articles) { article in
        calendar.startOfDay(for: article.publishDate)
    }
    
    return grouped.sorted { $0.key > $1.key }
}

func filterArticles(_ articles: [Article], searchText: String) -> [Article] {
    if searchText.isEmpty {
        return articles.sorted { $0.publishDate > $1.publishDate }
    }
    return articles
        .filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        .sorted { $0.publishDate > $1.publishDate }
} 