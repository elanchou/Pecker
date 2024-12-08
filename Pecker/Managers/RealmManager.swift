import Foundation
import RealmSwift

actor RealmManager {
    static let shared = RealmManager()
    private init() {}
    
    // MARK: - Feed Operations
    @MainActor
    func addNewFeed(_ feed: Feed) async throws {
        let realm = try await Realm()
        
        // 检查是否已存在相同 URL 的订阅
        if realm.objects(Feed.self).filter("url == %@", feed.url).first != nil {
            throw NSError(
                domain: "com.elanchou.pecker",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "该订阅源已存在"]
            )
        }
        
        try realm.write {
            realm.add(feed)
        }
    }
    
    @MainActor
    func addFeed(_ feed: Feed) async throws {
        try await addNewFeed(feed) // 为了保持兼容性，调用 addNewFeed
    }
    
    @MainActor
    func updateFeed(_ feed: Feed, with articles: [Article]) async throws {
        let realm = try await Realm()
        
        try realm.write {
            feed.lastUpdated = Date()
            
            for article in articles {
                if let existingArticle = realm.objects(Article.self).filter("url == %@", article.url).first {
                    // 更新现有文章
                    existingArticle.title = article.title
                    existingArticle.content = article.content
                    existingArticle.summary = article.summary
                    existingArticle.publishDate = article.publishDate
                    
                    // 确保文章与订阅源关联
                    if !feed.articles.contains(existingArticle) {
                        feed.articles.append(existingArticle)
                    }
                } else {
                    // 添加新文章
                    let newArticle = Article()
                    newArticle.id = article.id
                    newArticle.title = article.title
                    newArticle.content = article.content
                    newArticle.summary = article.summary
                    newArticle.url = article.url
                    newArticle.publishDate = article.publishDate
                    newArticle.imageURLs.append(objectsIn: article.imageURLs)
                    
                    realm.add(newArticle)
                    feed.articles.append(newArticle)
                    
                    if !newArticle.isRead {
                        feed.unreadCount += 1
                    }
                }
            }
        }
    }
    
    @MainActor
    func deleteFeed(_ feed: Feed) async throws {
        let realm = try await Realm()
        try realm.write {
            realm.delete(feed.articles)
            realm.delete(feed)
        }
    }
    
    // MARK: - Article Operations
    @MainActor
    func markArticleAsRead(_ articleId: String) async throws {
        let realm = try await Realm()
        guard let article = realm.object(ofType: Article.self, forPrimaryKey: articleId) else { return }
        
        try realm.write {
            if !article.isRead {
                article.isRead = true
                if let feed = article.feed.first {
                    feed.unreadCount = max(0, feed.unreadCount - 1)
                }
            }
        }
    }
    
    @MainActor
    func toggleArticleFavorite(_ articleId: String) async throws {
        let realm = try await Realm()
        guard let article = realm.object(ofType: Article.self, forPrimaryKey: articleId) else { return }
        
        try realm.write {
            article.isFavorite.toggle()
        }
    }
    
    @MainActor
    func markAllArticlesAsRead(in feed: Feed) async throws {
        let realm = try await Realm()
        try realm.write {
            let articles = realm.objects(Article.self).filter("ANY feed == %@", feed)
            articles.forEach { $0.isRead = true }
            feed.unreadCount = 0
        }
    }
    
    @MainActor
    func updateArticleSummary(_ articleId: String, summary: String) async throws {
        let realm = try await Realm()
        guard let article = realm.object(ofType: Article.self, forPrimaryKey: articleId) else { return }
        
        try realm.write {
            article.aiSummary = summary
        }
    }
    
    @MainActor
    func markArticleAsDeleted(_ articleId: String) async throws {
        let realm = try await Realm()
        guard let article = realm.object(ofType: Article.self, forPrimaryKey: articleId) else { return }
        
        try realm.write {
            article.isDeleted = true
        }
    }
    
    // MARK: - Query Operations
    @MainActor
    func getArticles(filter: String? = nil) -> Results<Article>? {
        guard let realm = try? Realm() else { return nil }
        var articles = realm.objects(Article.self).filter("isDeleted == false")
        if let filter = filter {
            articles = articles.filter(filter)
        }
        return articles
    }
    
    @MainActor
    func getFeeds() -> Results<Feed>? {
        guard let realm = try? Realm() else { return nil }
        return realm.objects(Feed.self).filter("isDeleted == false")
    }
    
    @MainActor
    func getArticle(byId id: String) -> Article? {
        guard let realm = try? Realm() else { return nil }
        return realm.object(ofType: Article.self, forPrimaryKey: id)
    }
    
    // MARK: - Settings Operations
    @MainActor
    func saveUserSettings(_ settings: [String: Any]) async throws {
        let realm = try await Realm()
        try realm.write {
            // 保存用户设置
            // 实现具体的设置保存逻辑
        }
    }
}
