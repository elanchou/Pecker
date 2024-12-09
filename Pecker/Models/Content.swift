import Foundation
import RealmSwift

class Content: Object, Identifiable {
    @Persisted(primaryKey: true) var id: String
    @Persisted var title: String = ""
    @Persisted var body: String = ""
    @Persisted var url: String = ""
    @Persisted var publishDate: Date = Date()
    @Persisted var summary: String?
    @Persisted var aiSummary: String?
    @Persisted var isRead: Bool = false
    @Persisted var isFavorite: Bool = false
    @Persisted var isDeleted: Bool = false
    @Persisted(originProperty: "contents") var feed: LinkingObjects<Feed>
    @Persisted var imageURLs = List<String>()
    @Persisted var updatedAt: Date = Date()
    
    convenience init(title: String, body: String, url: String) {
        self.init()
        self.id = UUID().uuidString
        self.title = title
        self.body = body
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
extension Content {
    static func findOrCreate(withUrl url: String, in realm: Realm) -> Content {
        if let existingContent = realm.objects(Content.self).filter("url == %@", url).first {
            return existingContent
        }
        
        let content = Content(title: "", body: "", url: url)
        try? realm.write {
            realm.add(content)
        }
        return content
    }
    
    @MainActor
    func markAsRead() async {
        try? await RealmManager.shared.markContentAsRead(id)
    }
    
    @MainActor
    func toggleFavorite() async {
        try? await RealmManager.shared.toggleContentFavorite(id)
    }
    
    @MainActor
    func markAsDeleted() async {
        try? await RealmManager.shared.markContentAsDeleted(id)
    }
    
    func updateSummary(_ summary: String) {
        Task { @MainActor in
            try? await RealmManager.shared.updateContentSummary(id, summary: summary)
        }
    }
    
    var validURL: URL? {
        guard let url = URL(string: url) else { return nil }
        return url.scheme?.lowercased().hasPrefix("http") == true ? url : nil
    }
}
