import FeedKit
import Foundation
import RealmSwift

actor RSSService {
    private let queue = DispatchQueue(label: "com.elanchou.pecker.rss", qos: .userInitiated)
    
    @MainActor
    func fetchFeed(url: String) async throws -> [Article] {
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
                    let articles: [Article]
                    switch feed {
                    case .atom(let atomFeed):
                        articles = self.parseAtomFeed(atomFeed)
                    case .rss(let rssFeed):
                        articles = self.parseRSSFeed(rssFeed)
                    case .json(let jsonFeed):
                        articles = self.parseJSONFeed(jsonFeed)
                    }
                    continuation.resume(returning: articles)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    @MainActor
    func updateFeed(_ feed: Feed) async throws {
        let articles = try await fetchFeed(url: feed.url)
        try await RealmManager.shared.updateFeed(feed, with: articles)
    }
    
    @MainActor
    func addNewFeed(url: String) async throws {
        let feed = Feed()
        feed.id = UUID().uuidString
        feed.url = url
        
        // 先获取文章以验证订阅源有效
        let articles = try await fetchFeed(url: url)
        
        // 如果成功获取文章，添加订阅源
        try await RealmManager.shared.addFeed(feed)
        try await RealmManager.shared.updateFeed(feed, with: articles)
    }
    
    @MainActor
    func updateFeedInfo(_ feed: Feed) async throws {
        let result = try await fetchFeed(url: feed.url)
        if let firstArticle = result.first {
            await MainActor.run {
                feed.title = firstArticle.feed.first?.title ?? "新订阅源"
                feed.iconURL = firstArticle.feed.first?.iconURL
            }
        }
    }
    
    private func parseAtomFeed(_ feed: AtomFeed) -> [Article] {
        return feed.entries?.compactMap { entry in
            let article = Article()
            article.id = entry.id ?? UUID().uuidString
            article.title = entry.title ?? "无标题"
            article.content = entry.content?.value ?? entry.summary?.value ?? ""
            article.url = entry.links?.first?.attributes?.href ?? ""
            article.publishDate = entry.published ?? Date()
            article.summary = entry.summary?.value
            
            if let content = entry.content?.value {
                article.imageURLs.append(objectsIn: extractImageURLs(from: content))
            }
            
            return article
        } ?? []
    }
    
    private func parseRSSFeed(_ feed: RSSFeed) -> [Article] {
        return feed.items?.compactMap { item in
            let article = Article()
            article.id = item.guid?.value ?? item.link ?? UUID().uuidString
            article.title = item.title ?? "无标题"
            article.content = item.content?.contentEncoded ?? item.description ?? ""
            article.url = item.link ?? ""
            article.publishDate = item.pubDate ?? Date()
            article.summary = item.description
            
            if let content = item.content?.contentEncoded ?? item.description {
                article.imageURLs.append(objectsIn: extractImageURLs(from: content))
            }
            
            return article
        } ?? []
    }
    
    private func parseJSONFeed(_ feed: JSONFeed) -> [Article] {
        return feed.items?.compactMap { item in
            let article = Article()
            article.id = item.id ?? item.url ?? UUID().uuidString
            article.title = item.title ?? "无标题"
            article.content = item.contentHtml ?? item.contentText ?? ""
            article.url = item.url ?? ""
            article.publishDate = item.datePublished ?? Date()
            article.summary = item.summary
            
            if let image = item.image {
                article.imageURLs.append(image)
            }
            
            return article
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
            let articleId = item.link ?? UUID().uuidString
            
            // 检查文章是否已存在
            if realm.object(ofType: Article.self, forPrimaryKey: articleId) != nil {
                // 如果文章已存在，跳过
                continue
            }
            
            // 创建新文章
            let article = Article()
            article.id = articleId
            article.title = item.title ?? ""
            article.content = item.description ?? ""
            article.url = item.link ?? ""
            article.publishDate = item.pubDate ?? Date()
            article.summary = item.description ?? ""
            
            // 处理图片 URL
            if let mediaContent = item.media?.mediaContents {
                for media in mediaContent {
                    if let url = media.attributes?.url {
                        article.imageURLs.append(url)
                    }
                }
            }
            
            // 添加到 Realm
            realm.add(article)
            feed.articles.append(article)
        }
    }
}
