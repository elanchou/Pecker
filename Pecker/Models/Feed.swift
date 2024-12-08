import Foundation
import RealmSwift

class Feed: Object, Identifiable {
    @Persisted(primaryKey: true) var id: String
    @Persisted var title: String = ""
    @Persisted var url: String = ""
    @Persisted var iconURL: String?
    @Persisted var category: String?
    @Persisted var unreadCount: Int = 0
    @Persisted var lastUpdated: Date = Date()
    @Persisted var cloudID: String?
    @Persisted var isDeleted: Bool = false
    @Persisted var articles: List<Article>
    
    convenience init(title: String, url: String) {
        self.init()
        self.id = UUID().uuidString
        self.title = title
        self.url = url
        self.lastUpdated = Date()
    }
}

// MARK: - Helper Functions
extension Feed {
    static func findOrCreate(withUrl url: String, in realm: Realm) -> Feed {
        if let existingFeed = realm.object(ofType: Feed.self, forPrimaryKey: url) {
            return existingFeed
        }
        
        let feed = Feed(title: "", url: url)
        try? realm.write {
            realm.add(feed)
        }
        return feed
    }
    
    func addArticle(_ article: Article) {
        let realm = try? Realm()
        try? realm?.write {
            articles.append(article)
            unreadCount += 1
        }
    }
    
    func removeArticle(_ article: Article) {
        let realm = try? Realm()
        try? realm?.write {
            if let index = articles.firstIndex(of: article) {
                if !article.isRead {
                    unreadCount = max(0, unreadCount - 1)
                }
                articles.remove(at: index)
            }
        }
    }
    
    func markAsDeleted() {
        let realm = try? Realm()
        try? realm?.write {
            isDeleted = true
        }
    }
} 
