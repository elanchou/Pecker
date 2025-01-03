import Foundation
import RealmSwift

actor RealmManager {
    static let shared = RealmManager()
    private init() {}
    
    func write(_ block: () -> Void) throws {
        let realm = try Realm()
        try realm.write {
            block()
        }
    }
    
    // 或者使用异步版本
    func write(_ block: @escaping () -> Void) async throws {
        let realm = try await Realm()
        try realm.write {
            block()
        }
    }
    
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
                    // 更新现有内容
                    existingContent.title = content.title
                    existingContent.body = content.body
                    existingContent.summary = content.summary
                    existingContent.publishDate = content.publishDate
                    existingContent.type = content.type
                    
                    // 更新播客特有属性
                    if content.type == .podcast {
                        existingContent.audioURL = content.audioURL
                        existingContent.duration = content.duration
                        // 保持播放进度不变
                    }
                    
                    // 确保内容与订阅源关联
                    if !feed.contents.contains(existingContent) {
                        feed.contents.append(existingContent)
                    }
                } else {
                    // 添加新内容
                    realm.add(content)
                    feed.contents.append(content)
                    
                    if !content.isRead {
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
    func clearCache() async throws {
        let realm = try await Realm()
        try await realm.asyncWrite {
            // 获取所有内容
            let contents = realm.objects(Content.self)
            
            // 只删除已读的内容
            let readContents = contents.filter("isRead == true")
            
            // 删除已读内容
            realm.delete(readContents)
        }
    }
    
    @MainActor
    func getFeeds() -> Results<Feed>? {
        guard let realm = try? Realm() else { return nil }
        return realm.objects(Feed.self).filter("isDeleted == false")
    }

    @MainActor
    func getFeeds(id: String? = nil) -> Results<Feed>? {
        guard let realm = try? Realm() else { return nil }
        var feeds = realm.objects(Feed.self).filter("isDeleted == false")
        if let id = id {
            feeds = feeds.filter("id == %@", id)
        }
        return feeds
    }
    
    @MainActor
    func getFeeds(filter: String? = nil) -> Results<Feed>? {
        guard let realm = try? Realm() else { return nil }
        var feeds = realm.objects(Feed.self).filter("isDeleted == false")
        if let filter = filter {
            feeds = feeds.filter(filter)
        }
        return feeds
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
    
    // MARK: - Playback Operations
    @MainActor
    func updatePlaybackPosition(_ contentId: String, position: TimeInterval) async throws {
        let realm = try await Realm()
        guard let content = realm.object(ofType: Content.self, forPrimaryKey: contentId) else { return }
        
        try realm.write {
            content.playbackPosition = position
        }
    }
}
