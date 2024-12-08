import UIKit

class TypewriterTextView: UITextView {
    private var displayLink: CADisplayLink?
    private var targetText: String = ""
    private var currentIndex: String.Index?
    private var typingSpeed: TimeInterval = 0.05 // 每个字符的打字间隔
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        isEditable = false
        isScrollEnabled = true
        backgroundColor = .clear
        textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        font = .systemFont(ofSize: 14)
        textColor = .secondaryLabel
        text = "" // 确保初始状态为空
        
        // 设置固定高度
        heightAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    func startTyping(_ text: String, completion: (() -> Void)? = nil) {
        self.text = "" // 清空现有文本
        targetText = text
        currentIndex = targetText.startIndex
        
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(updateText))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60)
        displayLink?.add(to: .main, forMode: .common)
        
        self.typingCompletion = completion
    }
    
    private var typingCompletion: (() -> Void)?
    
    @objc private func updateText() {
        guard let currentIndex = currentIndex else { return }
        
        if currentIndex < targetText.endIndex {
            let nextIndex = targetText.index(after: currentIndex)
            text = String(targetText[..<nextIndex])
            self.currentIndex = nextIndex
            
            // 自动滚动到底部
            scrollRangeToVisible(NSRange(location: text.count - 1, length: 1))
        } else {
            displayLink?.invalidate()
            displayLink = nil
            typingCompletion?()
        }
    }
    
    func stopTyping() {
        displayLink?.invalidate()
        displayLink = nil
        text = targetText
        typingCompletion?()
    }
} 