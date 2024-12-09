import Foundation
import RealmSwift

actor AISummaryService {
    private let apiKey: String = "ba077694-b76e-4921-81d0-62fbfe588af7"
    private let endpoint = "https://ark.cn-beijing.volces.com/api/v3/bots/chat/completions"
    
    @MainActor
    enum SummaryType {
        case singleContent(Content)
        case multipleContents([Content])
        case dailyDigest([Content])
        
        var model: String {
            switch self {
            case .singleContent:
                return "bot-20241208044143-d2mw2"  // 单文章摘要模型
            case .multipleContents, .dailyDigest:
                return "bot-20241208130849-cng7b"  // 多文章分析模型
            }
        }
        
        var prompt: String {
            switch self {
            case .singleContent(let content):
                return """
                请为以下文章生成一个简洁的摘要，重点突出文章的主要内容和关键信息：
                
                链接：\(content.url)
                
                要求：
                1. 保持客观准确
                2. 突出核心要点
                3. 语言简洁清晰
                4. 控制在200字以内
                """
                
            case .multipleContents(let contents):
                let urls = contents.prefix(10).map { "- \($0.url)" }.joined(separator: "\n")
                return """
                请分析以下相关文章，生成一个综合性的主题分析：
                
                链接：\(urls)
                
                请从以下几个方面进行分析：
                1. 主要话题和趋势
                2. 重要观点总结
                3. 值得关注的信息
                
                要求：
                1. 分析要有深度
                2. 突出重要信息
                3. 控制在300字以内
                """
                
            case .dailyDigest(let contents):
                let urls = contents.prefix(3).map { "- \($0.url)" }.joined(separator: "\n")
                return """
                请为以下今日新闻生成一个简洁的日报总结：
                
                链接：\(urls)
                
                要求：
                1. 分类整理重要新闻
                2. 突出重大事件和趋势
                3. 语言生动简洁
                4. 控制在400字以内
                """
            }
        }
        
        var systemPrompt: String {
            switch self {
            case .singleContent:
                return "你是一个专业的文章分析助手，善于提取文章重点并生成简洁的摘要。"
            case .multipleContents:
                return "你是一个专业的内容分析师，善于发现文章主题和趋势，并进行深度分析。"
            case .dailyDigest:
                return "你是一个专业的新闻编辑，善于整理和总结每日重要新闻，并以简洁明了的方式呈现。"
            }
        }
    }
    
    func generateSummary(for type: SummaryType) async throws -> String {
        let messages = await [
            ChatMessage(role: "system", content: type.systemPrompt),
            ChatMessage(role: "user", content: type.prompt)
        ]
        
        let request = await ChatRequest(
            model: type.model,
            messages: messages,
            temperature: 0.7,
            max_tokens: 2000
        )
        
        return try await sendRequest(request)
    }
    
    private func sendRequest(_ request: ChatRequest) async throws -> String {
        var urlRequest = URLRequest(url: URL(string: endpoint)!)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AIError.apiError(errorMessage)
            }
            
            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
            return chatResponse.choices.first?.message.content ?? ""
            
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.networkError(error)
        }
    }
}

// MARK: - Supporting Types
extension AISummaryService {
    enum AIError: Error {
        case invalidResponse
        case apiError(String)
        case networkError(Error)
    }
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }
    
    struct ChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let temperature: Double
        let max_tokens: Int
    }
    
    struct ChatResponse: Codable {
        let choices: [Choice]
        
        struct Choice: Codable {
            let message: ChatMessage
        }
    }
} 
