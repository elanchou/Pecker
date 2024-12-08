import Foundation
import RealmSwift

class Article: Object, Identifiable {
    @Persisted(primaryKey: true) var id: String
    @Persisted var title: String = ""
    @Persisted var content: String = ""
    @Persisted var url: String = ""
    @Persisted var publishDate: Date = Date()
    @Persisted var summary: String?
    @Persisted var aiSummary: String?
    @Persisted var isRead: Bool = false
    @Persisted var isFavorite: Bool = false
    @Persisted var isDeleted: Bool = false
    @Persisted(originProperty: "articles") var feed: LinkingObjects<Feed>
    @Persisted var imageURLs = List<String>()
    @Persisted var updatedAt: Date = Date()
    
    convenience init(title: String, content: String, url: String) {
        self.init()
        self.id = UUID().uuidString
        self.title = title
        self.content = content
        self.url = url
        self.publishDate = Date()
    }
    
    @MainActor
    func updateAISummary(_ summary: String) {
        guard let realm = try? Realm() else { return }
        try? realm.write {
            self.aiSummary = summary
            self.updatedAt = Date()
        }
    }
}

// MARK: - Helper Functions
extension Article {
    static func findOrCreate(withUrl url: String, in realm: Realm) -> Article {
        if let existingArticle = realm.objects(Article.self).filter("url == %@", url).first {
            return existingArticle
        }
        
        let article = Article(title: "", content: "", url: url)
        try? realm.write {
            realm.add(article)
        }
        return article
    }
    
    @MainActor
    func markAsRead() async {
        try? await RealmManager.shared.markArticleAsRead(id)
    }
    
    @MainActor
    func toggleFavorite() async {
        try? await RealmManager.shared.toggleArticleFavorite(id)
    }
    
    @MainActor
    func markAsDeleted() async {
        try? await RealmManager.shared.markArticleAsDeleted(id)
    }
    
    func updateSummary(_ summary: String) {
        Task { @MainActor in
            try? await RealmManager.shared.updateArticleSummary(id, summary: summary)
        }
    }
    
    var validURL: URL? {
        guard let url = URL(string: url) else { return nil }
        return url.scheme?.lowercased().hasPrefix("http") == true ? url : nil
    }
}
