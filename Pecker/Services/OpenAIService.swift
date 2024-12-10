import Foundation

actor OpenAIService {
    // MARK: - Properties
    private let apiKey: String = "ba077694-b76e-4921-81d0-62fbfe588af7"
    private let endpoint = "https://ark.cn-beijing.volces.com/api/v3/bots/chat/completions"
    private let defaultModel = "bot-20241208044143-d2mw2"
    
    // MARK: - Public Methods
    func sendMessage(_ messages: [ChatMessage], temperature: Double = 0.7, maxTokens: Int = 2000) async throws -> String {
        let request = ChatRequest(
            model: defaultModel,
            messages: messages,
            temperature: temperature,
            max_tokens: maxTokens
        )
        
        return try await sendRequest(request)
    }
    
    // MARK: - Private Methods
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
extension OpenAIService {
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