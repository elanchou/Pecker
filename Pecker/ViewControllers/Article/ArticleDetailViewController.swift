import UIKit
@preconcurrency import WebKit
import RealmSwift

class ArticleDetailViewController: BaseViewController {
    // MARK: - Properties
    private let articleId: String
    private var article: Content?
    private let aiService = AIService()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private let feedLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()
    
    private let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let settingsPanel: ArticleSettingsPanel = {
        let panel = ArticleSettingsPanel(frame: .zero)
        panel.isHidden = true
        panel.alpha = 0
        return panel
    }()
    
    // MARK: - Init
    init(articleId: String) {
        self.articleId = articleId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadArticle()
    }
    
    private func setupNavigationBar() {
        // 添加 AI 按钮到导航栏
        let aiButton = UIBarButtonItem(
            image: UIImage(systemName: "sparkles"),
            style: .plain,
            target: self,
            action: #selector(aiButtonTapped)
        )
        aiButton.tintColor = .systemPurple
        
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "textformat.size"),
            style: .plain,
            target: self,
            action: #selector(showSettings)
        )
        settingsButton.tintColor = .systemPurple
//        navigationItem.rightBarButtonItems = [settingsButton, aiButton]
        
        // 清除标题
        navigationItem.title = nil
    }
    
    private func setupUI() {
        [headerView, webView, loadingIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        [feedLabel, dateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview($0)
        }
        
        contentView.addSubview(settingsPanel)
        settingsPanel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            feedLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            feedLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            feedLabel.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -8),
            feedLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            
            dateLabel.topAnchor.constraint(equalTo: feedLabel.topAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            dateLabel.widthAnchor.constraint(equalToConstant: 100),
            
            webView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            settingsPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            settingsPanel.heightAnchor.constraint(equalToConstant: 140)
        ])
        
        webView.navigationDelegate = self
        settingsPanel.delegate = self
    }
    
    @objc private func aiButtonTapped() {
        guard let article = article else { return }
        let aiVC = AIViewController(content: article)
        let nav = UINavigationController(rootViewController: aiVC)
        present(nav, animated: true)
    }
    
    // MARK: - Data Loading
    private func loadArticle() {
        Task {
            await MainActor.run {
                do {
                    let realm = try Realm()
                    if let loadedArticle = realm.object(ofType: Content.self, forPrimaryKey: articleId) {
                        self.article = loadedArticle
                        loadContent()
                        markAsRead()
                    }
                } catch {
                    showError(error)
                }
            }
        }
    }
    
    private func loadContent() {
        guard let article = article else { return }
        
        feedLabel.text = article.feed.first?.title
        dateLabel.text = formatDate(article.publishDate)
        
        // 设置标题
        navigationItem.title = article.title
        
        // 构建 HTML 内容
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body {
                    font-family: -apple-system, system-ui;
                    line-height: 1.6;
                    padding: 16px;
                    margin: 0;
                    color: var(--text-color);
                    background-color: var(--background-color);
                }
                h1 {
                    font-size: 24px;
                    font-weight: 600;
                    margin-bottom: 16px;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 8px;
                    margin: 16px 0;
                }
                @media (prefers-color-scheme: dark) {
                    :root {
                        --text-color: #FFFFFF;
                        --background-color: #000000;
                    }
                }
                @media (prefers-color-scheme: light) {
                    :root {
                        --text-color: #000000;
                        --background-color: #FFFFFF;
                    }
                }
            </style>
        </head>
        <body>
            <h1>\(article.title)</h1>
            \(article.body)
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
    
    private func markAsRead() {
        Task {
            await article?.markAsRead()
        }
    }
    
    // MARK: - UI Updates
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "生成摘要失败",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func showSettings() {
        if settingsPanel.isHidden {
            settingsPanel.isHidden = false
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
                self.settingsPanel.alpha = 1
                self.settingsPanel.transform = .identity
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.settingsPanel.alpha = 0
                self.settingsPanel.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            } completion: { _ in
                self.settingsPanel.isHidden = true
            }
        }
    }
}

// MARK: - WKNavigationDelegate
extension ArticleDetailViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingIndicator.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
}

extension ArticleDetailViewController: ArticleSettingsPanelDelegate {
    func settingsPanel(_ panel: ArticleSettingsPanel, didChangeFontSize size: CGFloat) {
        // 更新 WebView 的字体大小
        webView.evaluateJavaScript("""
            document.body.style.fontSize = '\(size)px';
        """)
    }
    
    func settingsPanel(_ panel: ArticleSettingsPanel, didSelectFont font: String) {
        // 更新 WebView 的字体
        webView.evaluateJavaScript("""
            document.body.style.fontFamily = '\(font)';
        """)
    }
} 
