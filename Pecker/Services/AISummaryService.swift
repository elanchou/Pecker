import Foundation

class AISummaryService {
    // MARK: - Properties
    private let openAIService = OpenAIService()
    private var messageHistory: [OpenAIService.ChatMessage] = []
    
    // MARK: - Public Methods
    func chat(_ text: String) async throws -> String {
        let messages = createMessages(for: .normal, text: text)
        return try await openAIService.sendMessage(messages)
    }
    
    func chat(_ messages: [OpenAIService.ChatMessage]) async throws -> String {
        return try await openAIService.sendMessage(messages)
    }
    
    func continueChat(_ text: String) async throws -> String {
        messageHistory.append(OpenAIService.ChatMessage(role: "user", content: text))
        let response = try await openAIService.sendMessage(messageHistory)
        messageHistory.append(OpenAIService.ChatMessage(role: "assistant", content: response))
        return response
    }
    
    func clearHistory() {
        messageHistory.removeAll()
    }
    
    func generateSummary(for type: AISummaryType) -> [OpenAIService.ChatMessage] {
        let prompt = generatePrompt(for: type)
        let messages = createMessages(for: type, text: prompt)
        return messages
    }
    
    // MARK: - Private Methods
    private func createMessages(for type: AISummaryType, text: String) -> [OpenAIService.ChatMessage] {
        let systemPrompt = getSystemPrompt(for: type)
        return [
            OpenAIService.ChatMessage(role: "system", content: systemPrompt),
            OpenAIService.ChatMessage(role: "user", content: text)
        ]
    }
    
    private func getSystemPrompt(for type: AISummaryType) -> String {
        switch type {
        case .normal:
            return "你是一个专业的助手，善于分析和总结内容。"
        case .singleContent:
            return "你是一个专业的内容分析师，擅长提取文章的核心观点和关键信息。请用简洁的语言进行总结，保持客观中立的语气。"
        case .multipleContents:
            return "你是一个专业的内容分析师，擅长分析多篇文章的共同主题和趋势。请找出文章间的关联性，并提供深入的见解。"
        case .dailyDigest:
            return "你是一个专业的内容分析师，擅长分析订阅源的内容特点和趋势。请提供深入的分析和阅读建议。"
        }
    }
    
    private func generatePrompt(for type: AISummaryType) -> String {
        switch type {
        case .singleContent(let content):
            return generateSingleContentPrompt(content)
        case .multipleContents(let contents):
            return generateMultipleContentsPrompt(contents)
        case .dailyDigest(let contents):
            return generateFeedSummaryPrompt(contents)
        case .normal:
            return ""
        }
    }
    
    private func generateSingleContentPrompt(_ content: Content) -> String {
        let prompt = """
        请对以下文章进行总结：
        
        链接: \(content.url)
        
        要求：
        1. 提取文章的核心观点和关键信息
        2. 用简洁的语言进行总结
        3. 保持客观中立的语气
        4. 总结长度控制在200字以内
        """
        return prompt
    }
    
    private func generateMultipleContentsPrompt(_ contents: [Content]) -> String {
        let contentUrls = contents.map { content in
            """
            - \(content.url)
            """
        }.joined(separator: "\n")
        
        let prompt = """
        请对以下\(contents.count)篇文章进行整体分析和总结：
        
        链接: \(contentUrls)
        
        要求：
        1. 找出这些文章的共同主题或关联
        2. 总结主要观点和见解
        3. 指出重要的趋势或模式
        4. 总结长度控制在300字以内
        """
        return prompt
    }
    
    private func generateFeedSummaryPrompt(_ contents: [Content]) -> String {
        // 按订阅源分组
        var feedContents: [Feed: [Content]] = [:]
        contents.forEach { content in
            if let feed = content.feed.first {
                feedContents[feed, default: []].append(content)
            }
        }
        
        let summaries = feedContents.map { feed, contents in
            """
            订阅源：\(feed.title)
            文章数：\(contents.count)
            最新更新：\(formatDate(contents.map { $0.publishDate }.max() ?? Date()))
            主要内容：\(contents.prefix(3).map { $0.title }.joined(separator: "、"))
            """
        }.joined(separator: "\n\n")
        
        let prompt = """
        请对以下订阅源的内容进行整体分析和总结：
        
        \(summaries)
        
        要求：
        1. 分析每个订阅源的内容特点和倾向
        2. 找出热门话题和趋��
        3. 提供阅读建议
        4. 总结长度控制在500字以内
        """
        return prompt
    }
}

// MARK: - Helper
private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    formatter.locale = Locale.current
    return formatter.string(from: date)
}

// MARK: - Types
extension AISummaryService {
    enum AISummaryType {
        case normal
        case singleContent(Content)
        case multipleContents([Content])
        case dailyDigest([Content])
    }
} 
