import Foundation
import FeedKit

actor RSSDirectoryService {
    static let shared = RSSDirectoryService()
    private let jsonURL = "https://raw.githubusercontent.com/elanchou/awesome-rss-feeds/refs/heads/master/rss_feeds.json"
    private static let countryFlagBaseURL = "https://flagcdn.com/w80"
    
    enum RSSCategoryType: String, Codable {
        case category
        case country
    }
    
    struct RSSCategory: Codable, Identifiable, Equatable {
        let name: String
        let iconURL: String?
        let withCategoryURL: String?
        let withoutCategoryURL: String?
        
        var id: String {
            return name
        }
        
        var type: RSSCategoryType {
            return .country
        }
        
        var flagURL: String? {
            if type == .country {
                return "\(RSSDirectoryService.countryFlagBaseURL)/\(id).png"
            }
            return nil
        }
        
        enum CodingKeys: String, CodingKey {
            case name = "name"
            case iconURL = "icon_url"
            case withCategoryURL = "with_category"
            case withoutCategoryURL = "without_category"
        }
    }
    
    struct Feed: Codable, Identifiable {
        let id: String
        let title: String
        let description: String?
        let category: String?
        let iconURL: String?
        let feedURL: String
        let websiteURL: String?
        let language: String?
    }
    
    struct RSSData: Codable {
        let categories: [RSSCategory]
        let countries: [RSSCategory]
        let feeds: [Feed]?
        
        enum CodingKeys: String, CodingKey {
            case categories = "categories"
            case countries = "countries"
            case feeds
        }
    }
    
    private var cachedData: RSSData?
    private var cachedFeeds: [String: [Feed]] = [:]
    private var cachedRSS: [String: [Feed]] = [:]
    
    private init() {}
    
    private func fetchData() async throws -> RSSData {
        if let cachedData = cachedData {
            return cachedData
        }
        
        guard let url = URL(string: jsonURL) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let rssData = try JSONDecoder().decode(RSSData.self, from: data)
        cachedData = rssData
        return rssData
    }
    
    private func fetchOPMLFeeds(from urlString: String) async throws -> [Feed] {
        if let cachedFeeds = cachedFeeds[urlString] {
            return cachedFeeds
        }
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let parser = OPMLParser()
        
        guard let document = parser.parseOPML(data: data) else {
            throw URLError(.cannotParseResponse)
        }
        
        var feeds: [Feed] = []
        
        for outline in document.body.outlines {
            outline.feeds.forEach { feed in
                if let feed = createFeed(from: feed) {
                    feeds.append(feed)
                }
            }
        }
        
        cachedFeeds[urlString] = feeds
        return feeds
    }
    
    private func fetchRSSFeeds(from urlString: String) async throws -> [Feed] {
        if let cachedRSS = cachedRSS[urlString] {
            return cachedRSS
        }
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let parser = FeedParser(data: data)
        
        guard case .success(let result) = parser.parse() else {
            throw URLError(.cannotParseResponse)
        }
        
        var feeds: [Feed] = []
        
        if let rssFeed = result.rssFeed {
            for item in rssFeed.items ?? [] {
                if let feed = createFeed(from: item, category: "RSS") {
                    feeds.append(feed)
                }
            }
        }
        
        cachedRSS[urlString] = feeds
        return feeds
    }
    
    private func createFeed(from feed: OPMLFeed) -> Feed? {
        guard let title = feed.title,
              let feedURL = feed.xmlUrl else {
            return nil
        }
        
        return Feed(
            id: feedURL,
            title: title,
            description: feed.description,
            category: feed.category,
            iconURL: nil,
            feedURL: feedURL,
            websiteURL: feed.htmlUrl,
            language: nil
        )
    }
    
    private func createFeed(from item: RSSFeedItem, category: String) -> Feed? {
        guard let feedURL = item.link else {
            return nil
        }
        
        return Feed(
            id: feedURL,
            title: item.title ?? "Untitled",
            description: item.description ?? "No description",
            category: category,
            iconURL: nil,
            feedURL: feedURL,
            websiteURL: item.link,
            language: nil
        )
    }
    
    func getCategories() async throws -> [RSSCategory] {
        let data = try await fetchData()
        return data.categories
    }
    
    func getCountries() async throws -> [RSSCategory] {
        let data = try await fetchData()
        return data.countries
    }
    
    func getFeedsByCategory(_ category: RSSCategory) async throws -> [Feed] {
        if let withCategoryURL = category.withCategoryURL {
            return try await fetchOPMLFeeds(from: withCategoryURL)
        } else if let withoutCategoryURL = category.withoutCategoryURL {
            return try await fetchOPMLFeeds(from: withoutCategoryURL)
        }
        
        let data = try await fetchData()
        return data.feeds?.filter { feed in
            switch category.type {
            case .category:
                return feed.category == category.id
            case .country:
                return feed.language?.hasPrefix(category.id) ?? false
            }
        } ?? []
    }
    
    func getFeedsFromRSS(_ url: String) async throws -> [Feed] {
        return try await fetchRSSFeeds(from: url)
    }
    
    func clearCache() {
        cachedData = nil
        cachedFeeds.removeAll()
        cachedRSS.removeAll()
    }
}
