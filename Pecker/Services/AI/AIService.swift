import Foundation

class AIService {
    private let openAIService: OpenAIService?
    private let deepSeekService: DeepSeekService?
    private let volcService: VolcService?
    private var llmService: LLMService?
    private let logger = Logger(subsystem: "com.elanchou.pecker", category: "ai")
    
    init() {
        UserDefaults.standard.set("sk-b4b43f17497a413698ec24afa481b59c", forKey: "DeepSeekKey")
        UserDefaults.standard.set("ba077694-b76e-4921-81d0-62fbfe588af7", forKey: "VolcKey")
        // 从 UserDefaults 或其他配置中获取 API Key
        if let openAIKey = UserDefaults.standard.string(forKey: "OpenAIKey") {
            self.openAIService = OpenAIService(apiKey: openAIKey)
        } else {
            self.openAIService = nil
        }
        
        if let deepSeekKey = UserDefaults.standard.string(forKey: "DeepSeekKey") {
            self.deepSeekService = DeepSeekService(apiKey: deepSeekKey)
        } else {
            self.deepSeekService = nil
        }
        
        if let volcKey = UserDefaults.standard.string(forKey: "VolcKey") {
            self.volcService = VolcService(apiKey: volcKey)
        } else {
            self.volcService = nil
        }
        
        Task {
            self.llmService = await LLMService()
        }
    }
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
        
        init(role: String = "user", content: String) {
            self.role = role
            self.content = content
        }
    }
    
    enum AIProvider: String, CaseIterable {
        case openAI = "OpenAI"
        case deepSeek = "DeepSeek"
        case volc = "Volc"
        case llm = "LLM"
        
        static var `default`: AIProvider {
            // 从 UserDefaults 获取默认提供商
            if let provider = UserDefaults.standard.string(forKey: "DefaultAIProvider"),
               let value = AIProvider(rawValue: provider) {
                return value
            }
            return .volc
        }
    }
    
    func chat(_ prompt: String, provider: AIProvider? = nil) async throws -> String {
        return try await chat([.init(role: "user", content: prompt)], provider: provider)
    }
    
    func chat(_ messages: [ChatMessage], provider: AIProvider? = nil) async throws -> String {
        let selectedProvider = provider ?? AIProvider.default
        
        switch selectedProvider {
        case .openAI:
            guard let service = openAIService else {
                throw AIError.noAPIKey
            }
            return try await service.chat(messages)
        case .deepSeek:
            guard let service = deepSeekService else {
                throw AIError.noAPIKey
            }
            return try await service.chat(messages)
        case .volc:
            guard let service = volcService else {
                throw AIError.noAPIKey
            }
            return try await service.chat(messages)
        case .llm:
            guard let service = llmService else {
                throw AIError.noAPIKey
            }
            return try await service.chat(messages)
        }
    }
    
    func chatAsync(_ messages: [ChatMessage], provider: AIProvider? = nil) -> AsyncStream<String> {
        let selectedProvider = provider ?? AIProvider.default

        return AsyncStream { continuation in
            Task {
                switch selectedProvider {
                case .volc:
                    guard let service = volcService else {
                        continuation.finish()
                        return
                    }
                    let response = try await service.chat(messages)
                    
                    // 这里模拟流式输出
                    for chunk in response.splitWithGrowingChunks(1) {
                        continuation.yield(chunk)
                        try await Task.sleep(nanoseconds: 100_000_000)
                    }
                    continuation.finish()
                case.llm:
                    guard let service = llmService else {
                        continuation.finish()
                        return
                    }
                    let stream = await service.chatAsync(messages)

                    for await response in stream {
                        continuation.yield(response)
                    }
                    continuation.finish()
                default:
                    continuation.finish()
                }
            }
        }
    }
    
    func generateSummary(for content: ContentType) -> [ChatMessage] {
        let language = LocalizationManager.shared.currentLanguage == .english ? "英文": "中文"
        let systemMessage = ChatMessage(
            role: "system",
            content: "你是一个专业的内容分析师，擅长提取文章的核心观点和关键信息。请用简洁的语言进行总结，保持客观中立的语气。使用\(language)回复"
        )
        
        let userMessage: ChatMessage
        switch content {
        case .singleContent(let article):
            userMessage = ChatMessage(
                role: "user",
                content: """
                请帮我总结这篇文章的主要内容，包括以下几个方面：
                1. 文章的主要观点和结论
                2. 重要的论据和数据支持
                3. 作者的态度和立场
                4. 对读者的启示和建议
                使用\(language)回复
                
                文章内容如下：
                标题：\(article.title)
                正文：\(article.body)
                """
            )
            
        case .multipleContents(let articles):
            let articlesText = articles.map { "- \($0.title)" }.joined(separator: "\n")
            userMessage = ChatMessage(
                role: "user",
                content: """
                请帮我分析这组文章的共同主题和关联性，包括以下几个方面：
                1. 各篇文章的核心观点
                2. 文章之间的关联和差异
                3. 整体趋势和启示
                使用\(language)回复
                
                文章列表：
                \(articlesText)
                
                文章内容：
                \(articles.map { "《\($0.title)》\n\($0.body)" }.joined(separator: "\n\n"))
                """
            )
        }
        
        return [systemMessage, userMessage]
    }
    
    enum ContentType {
        case singleContent(Content)
        case multipleContents([Content])
    }
    
    enum AIError: LocalizedError {
        case unSupportStream
        case noAPIKey
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "未设置 API Key，请在设置中配置"
            case .unSupportStream:
                return "不支持流式输出"
            }
        }
    }
} 
