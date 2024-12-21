import Foundation

actor RSSDirectoryService {
    static let shared = RSSDirectoryService()
    
    private let feedlyBaseURL = "https://api.feedly.com/v3"
    private let feedCatBaseURL = "https://api.feedcat.net/api/v1"
    private let networkManager = NetworkManager.shared
    private let logger = Logger(subsystem: "com.elanchou.pecker", category: "rss")
    
    // MARK: - Models
    struct RSSFeed: Codable, Hashable {
        let id: String
        let title: String
        let url: String
        let description: String?
        let imageUrl: String?
        let iconUrl: String?
        let category: String?
        let language: String?
        let subscribers: Int?
        let topics: [String]?
        let lastUpdated: Date?
        let website: String?
        let isRecommended: Bool?
        let score: Double?
        
        enum CodingKeys: String, CodingKey {
            case id, title, url, description, imageUrl, iconUrl, category
            case language, subscribers, topics, lastUpdated, website
            case isRecommended = "recommended"
            case score
        }
        
        // MARK: - Hashable
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: RSSFeed, rhs: RSSFeed) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    struct RSSCategory: Codable, Hashable {
        let id: String
        let name: String
        let description: String?
        let feedCount: Int
        let iconName: String
        let color: String
        
        static func == (lhs: RSSCategory, rhs: RSSCategory) -> Bool {
            return lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    struct FeedlyCollection: Codable {
        let id: String
        let label: String
        let description: String?
        let feeds: [FeedlyFeed]
    }
    
    struct FeedlyFeed: Codable {
        let id: String
        let title: String
        let website: String?
        let subscribers: Int
        let velocity: Double
        let iconUrl: String?
        let visualUrl: String?
        let language: String?
        let topics: [String]?
    }
    
    struct FeedCatCategory: Codable {
        let id: String
        let name: String
        let feeds: [FeedCatFeed]
    }
    
    struct FeedCatFeed: Codable {
        let id: String
        let title: String
        let url: String
        let description: String?
        let icon: String?
        let subscribers: Int
        let language: String
    }
    
    // MARK: - Public Methods
    func getCategories() async throws -> [RSSCategory] {
        return [
            RSSCategory(id: "tech", name: "科技", description: "科技新闻和评论", feedCount: 100, iconName: "cpu", color: "#007AFF"),
            RSSCategory(id: "business", name: "商业", description: "商业新闻和分析", feedCount: 80, iconName: "chart.line.uptrend.xyaxis", color: "#34C759"),
            RSSCategory(id: "culture", name: "文化", description: "文化艺术", feedCount: 60, iconName: "books.vertical", color: "#FF9500"),
            RSSCategory(id: "reading", name: "阅读", description: "书评和阅读", feedCount: 50, iconName: "book", color: "#AF52DE"),
            RSSCategory(id: "programming", name: "编程", description: "编程技术", feedCount: 70, iconName: "chevron.left.forwardslash.chevron.right", color: "#FF2D55"),
            RSSCategory(id: "design", name: "设计", description: "设计相关", feedCount: 40, iconName: "paintbrush", color: "#5856D6"),
            RSSCategory(id: "lifestyle", name: "生活方式", description: "生活方式和兴趣爱好", feedCount: 90, iconName: "heart", color: "#FF3B30"),
            RSSCategory(id: "news", name: "新闻", description: "新闻资讯", feedCount: 120, iconName: "newspaper", color: "#007AFF"),
            RSSCategory(id: "podcast", name: "播客", description: "播客内容", feedCount: 65, iconName: "mic", color: "#FF9500"),
            RSSCategory(id: "photography", name: "摄影", description: "摄影艺术", feedCount: 45, iconName: "camera", color: "#5856D6"),
            RSSCategory(id: "gaming", name: "游戏", description: "游戏资讯", feedCount: 55, iconName: "gamecontroller", color: "#FF2D55"),
            RSSCategory(id: "movie", name: "影视", description: "电影电视", feedCount: 75, iconName: "film", color: "#AF52DE")
        ]
    }
    
    func getPopularFeeds() async throws -> [RSSFeed] {
        // 并发获取 Feedly 和 FeedCat 的热门源
        async let feedlyFeeds = getFeedlyPopularFeeds()
        async let feedCatFeeds = getFeedCatPopularFeeds()
        
        let (feedly, feedCat) = try await (feedlyFeeds, feedCatFeeds)
        
        // 合并结果并去重
        var uniqueFeeds = Set<RSSFeed>()
        uniqueFeeds.formUnion(feedly)
        uniqueFeeds.formUnion(feedCat)
        
        // 按订阅数排序
        return Array(uniqueFeeds).sorted { ($0.subscribers ?? 0) > ($1.subscribers ?? 0) }
    }
    
    func getFeedsByCategory(_ category: RSSCategory) async throws -> [RSSFeed] {
        // 并发获取两个平台的分类源
        async let feedlyFeeds = getFeedlyFeedsByCategory(category.id)
        async let feedCatFeeds = getFeedCatFeedsByCategory(category.id)
        
        let (feedly, feedCat) = try await (feedlyFeeds, feedCatFeeds)
        
        // 合并结果并去重
        var uniqueFeeds = Set<RSSFeed>()
        uniqueFeeds.formUnion(feedly)
        uniqueFeeds.formUnion(feedCat)
        
        // 按订阅数排序
        return Array(uniqueFeeds).sorted { ($0.subscribers ?? 0) > ($1.subscribers ?? 0) }
    }
    
    func searchFeeds(_ query: String) async throws -> [RSSFeed] {
        // 并发搜索两个平台
        async let feedlyResults = searchFeedlyFeeds(query)
        async let feedCatResults = searchFeedCatFeeds(query)
        
        let (feedly, feedCat) = try await (feedlyResults, feedCatResults)
        
        // 合并结果并去重
        var uniqueFeeds = Set<RSSFeed>()
        uniqueFeeds.formUnion(feedly)
        uniqueFeeds.formUnion(feedCat)
        
        // 按相关度和订阅数排序
        return Array(uniqueFeeds).sorted { feed1, feed2 in
            let score1 = (feed1.score ?? 0) * Double(feed1.subscribers ?? 0)
            let score2 = (feed2.score ?? 0) * Double(feed2.subscribers ?? 0)
            return score1 > score2
        }
    }
    
    // MARK: - Feedly API
    private func getFeedlyPopularFeeds() async throws -> [RSSFeed] {
        logger.info("获取 Feedly 热门订阅源")
        let endpoint = "/recommendations/topics/科技,新闻,文化"
        let headers = ["accept": "application/json"]
        
        let collections: [FeedlyCollection] = try await networkManager.request(
            endpoint,
            baseURL: feedlyBaseURL,
            headers: headers
        )
        
        return collections.flatMap { collection in
            collection.feeds.map { feed in
                RSSFeed(
                    id: feed.id,
                    title: feed.title,
                    url: feed.website ?? "",
                    description: nil,
                    imageUrl: feed.visualUrl,
                    iconUrl: feed.iconUrl,
                    category: collection.label,
                    language: feed.language,
                    subscribers: feed.subscribers,
                    topics: feed.topics,
                    lastUpdated: nil,
                    website: feed.website,
                    isRecommended: true,
                    score: feed.velocity
                )
            }
        }
    }
    
    private func getFeedlyFeedsByCategory(_ category: String) async throws -> [RSSFeed] {
        logger.info("获取 Feedly 分类订阅源: \(category)")
        let endpoint = "/streams/contents"
        let headers = ["accept": "application/json"]
        let queryItems = [URLQueryItem(name: "streamId", value: "feed/\(category)")]
        
        let feeds: [FeedlyFeed] = try await networkManager.request(
            endpoint,
            baseURL: feedlyBaseURL,
            headers: headers,
            queryItems: queryItems
        )
        
        return feeds.map { feed in
            RSSFeed(
                id: feed.id,
                title: feed.title,
                url: feed.website ?? "",
                description: nil,
                imageUrl: feed.visualUrl,
                iconUrl: feed.iconUrl,
                category: category,
                language: feed.language,
                subscribers: feed.subscribers,
                topics: feed.topics,
                lastUpdated: nil,
                website: feed.website,
                isRecommended: false,
                score: feed.velocity
            )
        }
    }
    
    private func searchFeedlyFeeds(_ query: String) async throws -> [RSSFeed] {
        logger.info("搜索 Feedly 订阅源: \(query)")
        let endpoint = "/search/feeds"
        let headers = ["accept": "application/json"]
        let queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "locale", value: "zh-CN")
        ]
        
        let feeds: [FeedlyFeed] = try await networkManager.request(
            endpoint,
            baseURL: feedlyBaseURL,
            headers: headers,
            queryItems: queryItems
        )
        
        return feeds.map { feed in
            RSSFeed(
                id: feed.id,
                title: feed.title,
                url: feed.website ?? "",
                description: nil,
                imageUrl: feed.visualUrl,
                iconUrl: feed.iconUrl,
                category: nil,
                language: feed.language,
                subscribers: feed.subscribers,
                topics: feed.topics,
                lastUpdated: nil,
                website: feed.website,
                isRecommended: false,
                score: feed.velocity
            )
        }
    }
    
    // MARK: - FeedCat API
    private func getFeedCatPopularFeeds() async throws -> [RSSFeed] {
        logger.info("获取 FeedCat 热门订阅源")
        let endpoint = "/feeds/popular"
        
        let feeds: [FeedCatFeed] = try await networkManager.request(
            endpoint,
            baseURL: feedCatBaseURL
        )
        
        return feeds.map { feed in
            RSSFeed(
                id: feed.id,
                title: feed.title,
                url: feed.url,
                description: feed.description,
                imageUrl: nil,
                iconUrl: feed.icon,
                category: nil,
                language: feed.language,
                subscribers: feed.subscribers,
                topics: nil,
                lastUpdated: nil,
                website: nil,
                isRecommended: false,
                score: nil
            )
        }
    }
    
    private func getFeedCatFeedsByCategory(_ category: String) async throws -> [RSSFeed] {
        logger.info("获取 FeedCat 分类订阅源: \(category)")
        let endpoint = "/categories/\(category)/feeds"
        
        let categoryData: FeedCatCategory = try await networkManager.request(
            endpoint,
            baseURL: feedCatBaseURL
        )
        
        return categoryData.feeds.map { feed in
            RSSFeed(
                id: feed.id,
                title: feed.title,
                url: feed.url,
                description: feed.description,
                imageUrl: nil,
                iconUrl: feed.icon,
                category: categoryData.name,
                language: feed.language,
                subscribers: feed.subscribers,
                topics: nil,
                lastUpdated: nil,
                website: nil,
                isRecommended: false,
                score: nil
            )
        }
    }
    
    private func searchFeedCatFeeds(_ query: String) async throws -> [RSSFeed] {
        logger.info("搜索 FeedCat 订阅源: \(query)")
        let endpoint = "/search"
        let queryItems = [URLQueryItem(name: "q", value: query)]
        
        let feeds: [FeedCatFeed] = try await networkManager.request(
            endpoint,
            baseURL: feedCatBaseURL,
            queryItems: queryItems
        )
        
        return feeds.map { feed in
            RSSFeed(
                id: feed.id,
                title: feed.title,
                url: feed.url,
                description: feed.description,
                imageUrl: nil,
                iconUrl: feed.icon,
                category: nil,
                language: feed.language,
                subscribers: feed.subscribers,
                topics: nil,
                lastUpdated: nil,
                website: nil,
                isRecommended: false,
                score: nil
            )
        }
    }
} 
