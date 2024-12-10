import UIKit
import Down

class AITextView: UITextView {
    // MARK: - Properties
    private var typingTimer: Timer?
    private var currentIndex = 0
    private var fullText = ""
    private var typingSpeed: TimeInterval = 0.02
    private var currentAttributedString: NSAttributedString?
    
    // MARK: - Init
    init() {
        super.init(frame: .zero, textContainer: nil)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .clear
        textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        font = .systemFont(ofSize: 17)
        textColor = .label
        isEditable = false
        isScrollEnabled = true
        showsVerticalScrollIndicator = true
        
        // 设置行间距
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8 // 增加行间距
        paragraphStyle.paragraphSpacing = 16 // 段落之间的间距
        typingAttributes = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 17),
            .foregroundColor: UIColor.label
        ]
    }
    
    // MARK: - Typing Animation
    func startTyping(_ text: String, isMarkdown: Bool = true) {
        stopTyping()
        
        if isMarkdown {
            do {
                let down = Down(markdownString: text)
                
                // 创建富文本
                let attributedString = try down.toAttributedString(stylesheet: markdownStylesheet)
                
                currentAttributedString = attributedString
                fullText = attributedString.string
                startTypingAnimation()
            } catch {
                print("Markdown parsing error: \(error)")
                fullText = text
                startTypingAnimation()
            }
        } else {
            fullText = text
            startTypingAnimation()
        }
    }
    
    private func startTypingAnimation() {
        currentIndex = 0
        typingTimer = Timer.scheduledTimer(
            withTimeInterval: typingSpeed,
            repeats: true
        ) { [weak self] timer in
            self?.typeNextCharacter()
        }
    }
    
    private func typeNextCharacter() {
        guard currentIndex < fullText.count else {
            stopTyping()
            return
        }
        
        let index = fullText.index(fullText.startIndex, offsetBy: currentIndex)
        let character = String(fullText[index])
        
        // 更新文本
        if currentIndex == 0 {
            if let attributedString = currentAttributedString {
                let range = NSRange(location: 0, length: 1)
                let substring = attributedString.attributedSubstring(from: range)
                attributedText = substring
            } else {
                text = character
            }
        } else {
            if let attributedString = currentAttributedString {
                let range = NSRange(location: 0, length: currentIndex + 1)
                let substring = attributedString.attributedSubstring(from: range)
                attributedText = substring
            } else {
                text?.append(character)
            }
        }
        
        // 自动滚动到底部
        let bottom = NSRange(location: (text?.count ?? 0) - 1, length: 1)
        scrollRangeToVisible(bottom)
        
        currentIndex += 1
    }
    
    func stopTyping() {
        typingTimer?.invalidate()
        typingTimer = nil
        
        // 直接显示完整文本
        if !fullText.isEmpty {
            if let attributedString = currentAttributedString {
                attributedText = attributedString
            } else {
                text = fullText
            }
        }
    }
    
    private var markdownStylesheet: String {
        """
        * { 
            color: \(UIColor.label.hexString);
            line-height: 1.6;
        }
        body { 
            font-size: 17px;
            margin: 0;
            padding: 0;
        }
        p {
            margin-bottom: 16px;
        }
        h1 { 
            font-size: 24px;
            font-weight: bold;
            margin: 24px 0 16px 0;
        }
        h2 { 
            font-size: 22px;
            font-weight: bold;
            margin: 20px 0 14px 0;
        }
        h3 { 
            font-size: 20px;
            font-weight: 600;
            margin: 18px 0 12px 0;
        }
        h4 { 
            font-size: 18px;
            font-weight: 600;
            margin: 16px 0 10px 0;
        }
        h5, h6 { 
            font-size: 17px;
            font-weight: 500;
            margin: 14px 0 8px 0;
        }
        code {
            font-family: Menlo;
            font-size: 15px;
            color: \(UIColor.systemPurple.hexString);
            background-color: \(UIColor.systemPurple.withAlphaComponent(0.1).hexString);
            padding: 2px 4px;
            border-radius: 4px;
        }
        a { 
            color: \(UIColor.systemBlue.hexString);
            text-decoration: none;
        }
        blockquote {
            color: \(UIColor.secondaryLabel.hexString);
            border-left: 4px solid \(UIColor.secondaryLabel.hexString);
            padding-left: 16px;
            margin: 16px 0;
            font-style: italic;
        }
        ul, ol {
            margin: 8px 0;
            padding-left: 24px;
        }
        li {
            margin: 4px 0;
        }
        """
    }
}

// MARK: - UIColor Extension
extension UIColor {
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
} 
