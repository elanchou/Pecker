//
//  LLMService.swift
//  Pecker
//
//  Created by elanchou on 2025/2/9.
//

import Foundation
import SwiftData

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
        self.appManager = AppManager()
        self.llm = LLMEvaluator()
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
}

extension LLMService {
    private func generate(message: String) async -> String? {
        if let currentThread = currentThread {
            generatingThreadID = currentThread.id
            appManager.playHaptic()
            sendMessage(Message(role: .user, content: message, thread: currentThread))
            if let modelName = appManager.currentModelName {
                let output = await llm.generate(modelName: modelName, thread: currentThread, systemPrompt: appManager.systemPrompt)
                await sendMessage(Message(role: .assistant, content: output, thread: currentThread, generatingTime: llm.thinkingTime))
                generatingThreadID = nil
                return  output
            }
        } else {
            let newThread = Thread()
            currentThread = newThread
            modelContext?.insert(newThread)
            try? modelContext?.save()
        }
        return nil
    }

    private func sendMessage(_ message: Message) {
        appManager.playHaptic()
        modelContext?.insert(message)
        try? modelContext?.save()
    }
}
