import Foundation
import FeedKit

actor RSSDirectoryService {
    static let shared = RSSDirectoryService()
    private let rsshubBaseURL = "https://rsshub.app"
    
    enum RSSCategoryType: String, Codable {
        case social = "社交媒体"
        case news = "新闻资讯"
        case tech = "科技"
        case finance = "金融"
        case entertainment = "娱乐"
        case life = "生活"
        case reading = "阅读"
        case other = "其他"
    }
    
    struct RSSCategory: Codable, Identifiable, Equatable {
        let id: String
        let name: String
        let type: RSSCategoryType
        let platforms: [RSSPlatform]
        
        static func == (lhs: RSSCategory, rhs: RSSCategory) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    struct RSSPlatform: Codable, Identifiable {
        let id: String
        let name: String
        let icon: String
        let baseURL: String
        let paths: [RSSPath]
    }
    
    struct RSSPath: Codable {
        let path: String
        let name: String
        let description: String
        let params: [RSSParam]
        let example: String?
    }
    
    struct RSSParam: Codable {
        let name: String
        let description: String
        let required: Bool
        let example: String?
    }
    
    struct Feed: Codable, Identifiable {
        let id: String
        let title: String
        let description: String?
        let category: String?
        let platform: String
        let feedURL: String
        let websiteURL: String?
        let language: String?
    }
    
    // 预定义的分类和平台
    private let predefinedCategories: [RSSCategory] = [
        RSSCategory(
            id: "social",
            name: "社交媒体",
            type: .social,
            platforms: [
                RSSPlatform(
                    id: "weibo",
                    name: "微博",
                    icon: "weibo",
                    baseURL: "/weibo",
                    paths: [
                        RSSPath(
                            path: "/user/:uid",
                            name: "用户微博",
                            description: "订阅用户发布的微博",
                            params: [
                                RSSParam(
                                    name: "uid",
                                    description: "用户 ID",
                                    required: true,
                                    example: "1195230310"
                                )
                            ],
                            example: "/weibo/user/1195230310"
                        )
                    ]
                ),
                RSSPlatform(
                    id: "zhihu",
                    name: "知乎",
                    icon: "zhihu",
                    baseURL: "/zhihu",
                    paths: [
                        RSSPath(
                            path: "/people/activities/:id",
                            name: "用户动态",
                            description: "订阅用户的知乎动态",
                            params: [
                                RSSParam(
                                    name: "id",
                                    description: "用户名",
                                    required: true,
                                    example: "people"
                                )
                            ],
                            example: "/zhihu/people/activities/people"
                        )
                    ]
                )
            ]
        ),
        RSSCategory(
            id: "tech",
            name: "科技",
            type: .tech,
            platforms: [
                RSSPlatform(
                    id: "github",
                    name: "GitHub",
                    icon: "github",
                    baseURL: "/github",
                    paths: [
                        RSSPath(
                            path: "/repos/:user",
                            name: "用户仓库",
                            description: "订阅用户的 GitHub 仓库更新",
                            params: [
                                RSSParam(
                                    name: "user",
                                    description: "用户名",
                                    required: true,
                                    example: "microsoft"
                                )
                            ],
                            example: "/github/repos/microsoft"
                        )
                    ]
                )
            ]
        )
    ]
    
    func getCategories() async -> [RSSCategory] {
        return predefinedCategories
    }
    
    func getPlatforms(for category: RSSCategory) async -> [RSSPlatform] {
        return category.platforms
    }
    
    func generateFeedURL(platform: RSSPlatform, path: RSSPath, params: [String: String]) -> String {
        var feedPath = path.path
        for (key, value) in params {
            feedPath = feedPath.replacingOccurrences(of: ":\(key)", with: value)
        }
        return rsshubBaseURL + platform.baseURL + feedPath
    }
    
    func validateFeed(_ url: String) async throws -> Feed {
        guard let feedURL = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: feedURL)
        let parser = FeedParser(data: data)
        let result = parser.parse()
        
        switch result {
        case .success(let feed):
            switch feed {
            case .atom(let atomFeed):
                return Feed(
                    id: url,
                    title: atomFeed.title ?? "未知标题",
                    description: atomFeed.subtitle?.value,
                    category: nil,
                    platform: "RSSHub",
                    feedURL: url,
                    websiteURL: atomFeed.links?.first?.attributes?.href,
                    language: nil
                )
                
            case .rss(let rssFeed):
                return Feed(
                    id: url,
                    title: rssFeed.title ?? "未知标题",
                    description: rssFeed.description,
                    category: nil,
                    platform: "RSSHub",
                    feedURL: url,
                    websiteURL: rssFeed.link,
                    language: rssFeed.language
                )
                
            case .json(let jsonFeed):
                return Feed(
                    id: url,
                    title: jsonFeed.title ?? "未知标题",
                    description: jsonFeed.description,
                    category: nil,
                    platform: "RSSHub",
                    feedURL: url,
                    websiteURL: jsonFeed.homePageURL,
                    language: nil
                )
            }
            
        case .failure(let error):
            throw error
        }
    }
    
    func subscribe(_ feed: Feed) async throws {
        // 调用 RSSService 添加订阅
        try await RSSService.shared.addNewFeed(url: feed.feedURL)
    }
}
