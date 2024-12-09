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
    func updateFeed(_ feed: Feed, with contents: [Content]) async throws {
        let realm = try await Realm()
        
        try realm.write {
            feed.lastUpdated = Date()
            
            for content in contents {
                if let existingContent = realm.objects(Content.self).filter("url == %@", content.url).first {
                    // 更新现有文章
                    existingContent.title = content.title
                    existingContent.body = content.body
                    existingContent.summary = content.summary
                    existingContent.publishDate = content.publishDate
                    
                    // 确保文章与订阅源关联
                    if !feed.contents.contains(existingContent) {
                        feed.contents.append(existingContent)
                    }
                } else {
                    // 添加新文章
                    let newContent = Content()
                    newContent.id = content.id
                    newContent.title = content.title
                    newContent.body = content.body
                    newContent.summary = content.summary
                    newContent.url = content.url
                    newContent.publishDate = content.publishDate
                    newContent.imageURLs.append(objectsIn: content.imageURLs)
                    
                    realm.add(newContent)
                    feed.contents.append(newContent)
                    
                    if !newContent.isRead {
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
            realm.delete(feed.contents)
            realm.delete(feed)
        }
    }
    
    // MARK: - Content Operations
    @MainActor
    func markContentAsRead(_ contentId: String) async throws {
        let realm = try await Realm()
        guard let content = realm.object(ofType: Content.self, forPrimaryKey: contentId) else { return }
        
        try realm.write {
            if !content.isRead {
                content.isRead = true
                if let feed = content.feed.first {
                    feed.unreadCount = max(0, feed.unreadCount - 1)
                }
            }
        }
    }
    
    @MainActor
    func toggleContentFavorite(_ contentId: String) async throws {
        let realm = try await Realm()
        guard let content = realm.object(ofType: Content.self, forPrimaryKey: contentId) else { return }
        
        try realm.write {
            content.isFavorite.toggle()
        }
    }
    
    @MainActor
    func markAllContentsAsRead(in feed: Feed) async throws {
        let realm = try await Realm()
        try realm.write {
            let contents = realm.objects(Content.self).filter("ANY feed == %@", feed)
            contents.forEach { $0.isRead = true }
            feed.unreadCount = 0
        }
    }
    
    @MainActor
    func updateContentSummary(_ contentId: String, summary: String) async throws {
        let realm = try await Realm()
        guard let content = realm.object(ofType: Content.self, forPrimaryKey: contentId) else { return }
        
        try realm.write {
            content.aiSummary = summary
        }
    }
    
    @MainActor
    func markContentAsDeleted(_ contentId: String) async throws {
        let realm = try await Realm()
        guard let content = realm.object(ofType: Content.self, forPrimaryKey: contentId) else { return }
        
        try realm.write {
            content.isDeleted = true
        }
    }
    
    // MARK: - Query Operations
    @MainActor
    func getContents(filter: String? = nil) -> Results<Content>? {
        guard let realm = try? Realm() else { return nil }
        var contents = realm.objects(Content.self).filter("isDeleted == false")
        if let filter = filter {
            contents = contents.filter(filter)
        }
        return contents
    }
    
    @MainActor
    func getFeeds() -> Results<Feed>? {
        guard let realm = try? Realm() else { return nil }
        return realm.objects(Feed.self).filter("isDeleted == false")
    }
    
    @MainActor
    func getContent(byId id: String) -> Content? {
        guard let realm = try? Realm() else { return nil }
        return realm.object(ofType: Content.self, forPrimaryKey: id)
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
