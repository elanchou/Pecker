//
//  LLMService.swift
//  Pecker
//
//  Created by elanchou on 2025/2/9.
//

import Foundation
import SwiftData
import Combine

class LLMService {
    private let appManager: AppManager
    private let llm: LLMEvaluator
    private var modelContext: ModelContext?
    private var generatingThreadID: UUID?
    private var currentThread: Thread?
    private let logger = Logger(subsystem: "com.elanchou.pecker", category: "llm")
    
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
    
    @MainActor
    init() {
        self.appManager = AppManager.shared
        self.llm = LLMEvaluator.shared
        if let container = try? ModelContainer(for: Message.self) {
            self.modelContext = ModelContext(container)
        }
    }
    
    func chat(_ messages: [AIService.ChatMessage]) async throws -> String {
        let content = messages.last?.content ?? ""
        if let output = await self.generate(message: content) {
            return output
        } else {
            throw AIError.invalidResponse
        }
    }
    
    @MainActor
    func chatAsync(_ messages: [AIService.ChatMessage]) -> AsyncStream<String> {
        return AsyncStream { continuation in
            // 监听 llm.output，每次更新就 yield
            self.llm.onStream = { output in
                continuation.yield(output)
            }
            
            // 启动生成过程
            Task {
                let content = messages.last?.content ?? ""
                _ = await self.generate(message: content)
                continuation.finish()
            }
        }
    }

}

extension LLMService {
    private func generate(message: String) async -> String? {
        if currentThread == nil {
            let newThread = Thread()
            currentThread = newThread
            modelContext?.insert(newThread)
            try? modelContext?.save()
        }
        
        if let currentThread = currentThread {
            generatingThreadID = currentThread.id
            sendMessage(Message(role: .user, content: message, thread: currentThread))
            if let modelName = appManager.currentModelName {
                let output = await llm.generate(modelName: modelName, thread: currentThread, systemPrompt: appManager.systemPrompt)
                await sendMessage(Message(role: .assistant, content: output, thread: currentThread, generatingTime: llm.thinkingTime))
                generatingThreadID = nil
                return output
            }
        }
        return nil
    }

    private func sendMessage(_ message: Message) {
        modelContext?.insert(message)
        try? modelContext?.save()
    }
}
