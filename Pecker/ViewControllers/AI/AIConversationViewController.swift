import UIKit

class AIConversationViewController: BaseViewController {
    // MARK: - Properties
    private let article: Article
    
    private let conversationTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.isEditable = false
        return textView
    }()
    
    // MARK: - Init
    init(article: Article) {
        self.article = article
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadConversation()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(conversationTextView)
        conversationTextView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            conversationTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            conversationTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            conversationTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            conversationTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Load Conversation
    private func loadConversation() {
        // 这里可以添加 AI 生成摘要的逻辑
        conversationTextView.text = "AI 生成的摘要内容"
    }
} 
