import UIKit

class AIAssistantManager {
    // MARK: - Singleton
    static let shared = AIAssistantManager()
    private init() {}
    
    // MARK: - Properties
    private var assistantView: AIAssistantView?
    
    // MARK: - Public Methods
    func setup(in window: UIWindow) {
        // 创建 AIAssistantView
        let assistant = AIAssistantView()
        window.addSubview(assistant)
        
        // 设置初始状态（在屏幕外，透明度为 0）
        assistant.alpha = 0
        assistant.transform = CGAffineTransform(translationX: 0, y: 50)
        
        // 设置约束
        assistant.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(window.safeAreaLayoutGuide).offset(-100)
        }
        
        // 动画显示
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            assistant.alpha = 1
            assistant.transform = .identity // 复位到原始位置
        })
        
        self.assistantView = assistant
    }
    
    func expand() {
        assistantView?.expand()
    }
    
    func collapse() {
        assistantView?.collapse()
    }
    
    func addInsight(_ insight: AIInsight) {
        self.expand()
        assistantView?.addInsight(insight)
    }
    
    func startThinking() {
        self.expand()
        assistantView?.startThinking()
    }
    
    func stopThinking() {
        self.expand()
        assistantView?.stopThinking()
    }
} 
