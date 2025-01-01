import FeedKit
import Foundation
import RealmSwift

actor RSSService {
    static let shared = RSSService()
    private let queue = DispatchQueue(label: "com.elanchou.pecker.rss", qos: .userInitiated)
    
    @MainActor
    func addNewFeed(url: String) async throws {
        let feed = Feed()
        feed.id = UUID().uuidString
        feed.url = url
        
        // 先获取文章以验证订阅源有效
        let contents = try await fetchFeed(url: url)
        
        // 如果成功获取文章，添加订阅源
        try await RealmManager.shared.addFeed(feed)
        try await RealmManager.shared.updateFeed(feed, with: contents)
    }
    
    @MainActor
    func fetchFeed(url: String) async throws -> [Content] {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                guard let feedURL = URL(string: url) else {
                    continuation.resume(throwing: URLError(.badURL))
                    return
                }
                
                let parser = FeedParser(URL: feedURL)
                let result = parser.parse()
                
                switch result {
                case .success(let feed):
                    let contents: [Content]
                    switch feed {
                    case .atom(let atomFeed):
                        contents = self.parseAtomFeed(atomFeed)
                    case .rss(let rssFeed):
                        contents = self.parseRSSFeed(rssFeed)
                    case .json(let jsonFeed):
                        contents = self.parseJSONFeed(jsonFeed)
                    }
                    continuation.resume(returning: contents)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    @MainActor
    func updateFeed(_ feed: Feed) async throws {
        let contents = try await fetchFeed(url: feed.url)
        try await RealmManager.shared.updateFeed(feed, with: contents)
    }
    
    @MainActor
    func fetchFeedInfo(url urlString: String) async throws -> Feed {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        // 检查是否已存在相同 URL 的订阅
        let realm = try await Realm()
        if realm.objects(Feed.self).filter("url == %@", urlString).first != nil {
            throw NSError(
                domain: "com.elanchou.pecker",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "该订阅源已存在"]
            )
        }
        
        // 创建新的 Feed
        let feed = Feed()
        feed.id = UUID().uuidString
        feed.url = urlString
        
        // 获取订阅源信息
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let parser = FeedParser(URL: url)
                let result = parser.parse()
                
                switch result {
                case .success(let parsedFeed):
                    switch parsedFeed {
                    case .atom(let atomFeed):
                        feed.title = atomFeed.title ?? "未命名订阅源"
                        feed.iconURL = atomFeed.icon ?? atomFeed.logo
                        feed.feedType = .article
                        
                    case .rss(let rssFeed):
                        feed.title = rssFeed.title ?? "未命名订阅源"
                        feed.iconURL = rssFeed.image?.url
                        
                        // 检查是否为播客
                        if rssFeed.iTunes != nil {
                            feed.feedType = .podcast
                        } else {
                            feed.feedType = .article
                        }
                        
                    case .json(let jsonFeed):
                        feed.title = jsonFeed.title ?? "未命名订阅源"
                        feed.iconURL = jsonFeed.icon ?? jsonFeed.favicon
                        feed.feedType = .article
                    }
                    continuation.resume(returning: feed)
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func parseAtomFeed(_ feed: AtomFeed) -> [Content] {
        return feed.entries?.compactMap { entry in
            let content = Content()
            content.id = entry.id ?? UUID().uuidString
            content.title = entry.title ?? "无标题"
            content.body = entry.content?.value ?? entry.summary?.value ?? ""
            content.url = entry.links?.first?.attributes?.href ?? ""
            content.publishDate = entry.published ?? Date()
            content.summary = entry.summary?.value
            
            if let entryContent = entry.content?.value {
                content.imageURLs.append(objectsIn: extractImageURLs(from: entryContent))
            }
            
            return content
        } ?? []
    }
    
    private func parseRSSFeed(_ feed: RSSFeed) -> [Content] {
        if feed.iTunes != nil {
            // 如果是播客，解析音频内容
            return feed.items?.compactMap { item in
                let content = Content()
                content.id = item.guid?.value ?? item.link ?? UUID().uuidString
                content.title = item.title ?? "无标题"
                content.body = item.description ?? ""
                content.url = item.link ?? ""
                content.audioURL = item.enclosure?.attributes?.url
                content.publishDate = item.pubDate ?? Date()
                content.summary = item.description
                content.duration = TimeInterval(item.iTunes?.iTunesDuration ?? 0)
                content.type = .podcast
                
                // 处理图片
                if let imageURL = item.iTunes?.iTunesImage?.attributes?.href ?? feed.iTunes?.iTunesImage?.attributes?.href ?? feed.image?.url {
                    content.imageURLs.append(imageURL)
                }
                
                return content
            } ?? []
        } else {
            // 原有的文章解析逻辑
            return feed.items?.compactMap { item in
                let content = Content()
                content.id = item.guid?.value ?? item.link ?? UUID().uuidString
                content.title = item.title ?? "无标题"
                content.body = item.content?.contentEncoded ?? item.description ?? ""
                content.url = item.link ?? ""
                content.publishDate = item.pubDate ?? Date()
                content.summary = item.description
                content.type = .article
                
                if let itemContent = item.content?.contentEncoded ?? item.description {
                    content.imageURLs.append(objectsIn: extractImageURLs(from: itemContent))
                }
                
                return content
            } ?? []
        }
    }
    
    private func parseJSONFeed(_ feed: JSONFeed) -> [Content] {
        return feed.items?.compactMap { item in
            let content = Content()
            content.id = item.id ?? item.url ?? UUID().uuidString
            content.title = item.title ?? "无标题"
            content.body = item.contentHtml ?? item.contentText ?? ""
            content.url = item.url ?? ""
            content.publishDate = item.datePublished ?? Date()
            content.summary = item.summary
            
            if let image = item.image {
                content.imageURLs.append(image)
            }
            
            return content
        } ?? []
    }
    
    private func extractImageURLs(from content: String) -> [String] {
        let pattern = #"<img[^>]+src=\"([^\"]+)\""#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(content.startIndex..., in: content)
        let matches = regex?.matches(in: content, range: range) ?? []
        
        return matches.compactMap { match in
            guard let urlRange = Range(match.range(at: 1), in: content) else { return nil }
            return String(content[urlRange])
        }
    }
    
    private func processRSSItems(_ items: [RSSFeedItem], for feed: Feed, in realm: Realm) async throws {
        for item in items {
            // 使用 URL 作为唯一标识
            let contentId = item.link ?? UUID().uuidString
            
            // 检查文章是否已存在
            if realm.object(ofType: Content.self, forPrimaryKey: contentId) != nil {
                // 如果文章已存在，跳过
                continue
            }
            
            // 创建新文章
            let content = Content()
            content.id = contentId
            content.title = item.title ?? ""
            content.body = item.description ?? ""
            content.url = item.link ?? ""
            content.publishDate = item.pubDate ?? Date()
            content.summary = item.description ?? ""
            
            // 处理图片 URL
            if let mediaContent = item.media?.mediaContents {
                for media in mediaContent {
                    if let url = media.attributes?.url {
                        content.imageURLs.append(url)
                    }
                }
            }
            
            // 添加到 Realm
            realm.add(content)
            feed.contents.append(content)
        }
    }
}
