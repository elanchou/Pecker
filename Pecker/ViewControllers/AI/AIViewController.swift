import UIKit

class AIViewController: BaseViewController {
    private let content: Content
    private let aiService = AISummaryService()
    
    private let loadingView = LoadingBirdView()
    
    private let textView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .label
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isHidden = true
        textView.alpha = 0
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        return textView
    }()
    
    init(content: Content) {
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        generateSummary()
    }
    
    private func setupUI() {
        title = "AI 分析"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "关闭",
            style: .done,
            target: self,
            action: #selector(dismissVC)
        )
        
        [loadingView, textView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            loadingView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            
            textView.topAnchor.constraint(equalTo: contentView.topAnchor),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private func generateSummary() {
        loadingView.startLoading()
        
        Task { @MainActor in
            do {
                let summary = try await aiService.generateSummary(for: .singleContent(content))
                loadingView.stopLoading { [weak self] in
                    self?.showResult(summary)
                }
            } catch {
                loadingView.stopLoading { [weak self] in
                    self?.showError(error)
                }
            }
        }
    }
    
    private func showResult(_ content: String) {
        textView.text = content
        
        UIView.animate(withDuration: 0.3) {
            self.loadingView.alpha = 0
            self.textView.isHidden = false
            self.textView.alpha = 1
        } completion: { _ in
            self.loadingView.isHidden = true
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "分析失败",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    @objc private func dismissVC() {
        dismiss(animated: true)
    }
} 
