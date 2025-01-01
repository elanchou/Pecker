import Foundation

class DeepSeekService {
    private let apiKey: String
    private let baseURL = "https://api.deepseek.com/v1"
    private let logger = Logger(subsystem: "com.elanchou.pecker", category: "deepseek")
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    enum AIError: Error {
        case invalidResponse
        case apiError(String)
        case networkError(Error)
    }
    
    struct ChatRequest: Codable {
        let model: String
        let messages: [AIService.ChatMessage]
        let temperature: Double
        let max_tokens: Int
    }
    
    struct ChatResponse: Codable {
        let choices: [Choice]
        
        struct Choice: Codable {
            let message: AIService.ChatMessage
        }
    }
    
    func chat(_ messages: [AIService.ChatMessage]) async throws -> String {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let chatRequest = ChatRequest(
            model: "deepseek-chat",
            messages: messages,
            temperature: 0.7,
            max_tokens: 2000
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(chatRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AIError.apiError(errorMessage)
            }
            
            let decoder = JSONDecoder()
            let chatResponse = try decoder.decode(ChatResponse.self, from: data)
            
            guard let message = chatResponse.choices.first?.message else {
                throw AIError.invalidResponse
            }
            
            return message.content
            
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.networkError(error)
        }
    }
} 