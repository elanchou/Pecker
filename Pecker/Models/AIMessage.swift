import Foundation

struct AIMessage {
    let id: String
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    
    init(text: String, isFromUser: Bool) {
        self.id = UUID().uuidString
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = Date()
    }
} 
