import Foundation

actor WebsiteMetadataService {
    static let shared = WebsiteMetadataService()
    
    struct WebsiteMetadata {
        let iconUrl: String?
        let imageUrl: String?
        let title: String?
        let description: String?
    }
    
    private let cache = NSCache<NSString, NSString>()
    
    func getMetadata(for url: String) async throws -> WebsiteMetadata {
        guard let feedUrl = URL(string: url),
              let host = feedUrl.host else {
            throw NSError(domain: "WebsiteMetadataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // 获取网站图标
        let iconUrl = "https://www.google.com/s2/favicons?domain=\(host)&sz=128"
        
        // 尝试从缓存获取图片 URL
        if let cachedImageUrl = cache.object(forKey: host as NSString) as String? {
            return WebsiteMetadata(
                iconUrl: iconUrl,
                imageUrl: cachedImageUrl,
                title: nil,
                description: nil
            )
        }
        
        // 尝试获取网站预览图
        let previewUrl = "https://api.urlmeta.org/?url=https://\(host)"
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: previewUrl)!)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let result = json["result"] as? [String: Any],
               let image = result["image"] as? String {
                cache.setObject(image as NSString, forKey: host as NSString)
                return WebsiteMetadata(
                    iconUrl: iconUrl,
                    imageUrl: image,
                    title: result["title"] as? String,
                    description: result["description"] as? String
                )
            }
        } catch {
            // 如果获取预览图失败，尝试使用 og:image
            if let url = URL(string: "https://\(host)") {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let html = String(data: data, encoding: .utf8) {
                        let ogImage = extractMetaContent(from: html, property: "og:image")
                        let ogTitle = extractMetaContent(from: html, property: "og:title")
                        let ogDescription = extractMetaContent(from: html, property: "og:description")
                        
                        if let imageUrl = ogImage {
                            cache.setObject(imageUrl as NSString, forKey: host as NSString)
                            return WebsiteMetadata(
                                iconUrl: iconUrl,
                                imageUrl: imageUrl,
                                title: ogTitle,
                                description: ogDescription
                            )
                        }
                    }
                } catch {
                    print("Failed to fetch og:image: \(error)")
                }
            }
        }
        
        // 如果所有尝试都失败，返回只有图标的元数据
        return WebsiteMetadata(
            iconUrl: iconUrl,
            imageUrl: nil,
            title: nil,
            description: nil
        )
    }
    
    private func extractMetaContent(from html: String, property: String) -> String? {
        let pattern = "<meta\\s+property=\"\(property)\"\\s+content=\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range),
              let contentRange = Range(match.range(at: 1), in: html) else {
            return nil
        }
        
        return String(html[contentRange])
    }
} 
