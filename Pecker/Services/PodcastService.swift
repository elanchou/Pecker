import Foundation

actor PodcastService {
    static let shared = PodcastService()
    private let baseURL = "https://itunes.apple.com"
    
    struct PodcastResult: Codable {
        let resultCount: Int
        let results: [Podcast]
    }
    
    struct Podcast: Codable {
        let collectionId: Int
        let collectionName: String
        let artistName: String
        let artworkUrl600: String?
        let feedUrl: String?
        let genres: [String]?
        let description: String?
    }
    
    func searchPodcasts(_ query: String) async throws -> [Podcast] {
        var components = URLComponents(string: "\(baseURL)/search")
        components?.queryItems = [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "entity", value: "podcast"),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "country", value: "CN"),
            URLQueryItem(name: "lang", value: "zh_cn")
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // 打印响应数据用于调试
        if let jsonString = String(data: data, encoding: .utf8) {
            print("API Response: \(jsonString)")
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(PodcastResult.self, from: data)
        return result.results
    }
    
    func getTopPodcasts(genre: Int? = nil) async throws -> [Podcast] {
        var components = URLComponents(string: "\(baseURL)/rss/toppodcasts/limit=50/json")
        var queryItems = [URLQueryItem(name: "country", value: "CN")]
        if let genre = genre {
            queryItems.append(URLQueryItem(name: "genre", value: String(genre)))
        }
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // 打印响应数据用于调试
        if let jsonString = String(data: data, encoding: .utf8) {
            print("API Response: \(jsonString)")
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(PodcastResult.self, from: data)
        return result.results
    }
    
    func getPodcastGenres() async throws -> [Genre] {
        let url = URL(string: "\(baseURL)/WebObjects/MZStoreServices.woa/ws/genres")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // 打印响应数据用于调试
        if let jsonString = String(data: data, encoding: .utf8) {
            print("API Response: \(jsonString)")
        }
        
        let decoder = JSONDecoder()
        let genres = try decoder.decode([String: Genre].self, from: data)
        return Array(genres.values)
            .filter { $0.name.contains("播客") || $0.name.contains("Podcast") }
            .sorted { $0.name < $1.name }
    }
}
