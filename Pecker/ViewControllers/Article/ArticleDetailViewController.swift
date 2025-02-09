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
        panel.layer.cornerRadius = 16
        panel.clipsToBounds = true
        return panel
    }()
    
    private let settingsBackdrop: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemMaterial)
        let view = UIVisualEffectView(effect: blur)
        view.alpha = 0
        view.isHidden = true
        return view
    }()
    
    private let scrollToTopButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        button.tintColor = .systemPurple
        button.alpha = 0
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        return button
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
        [headerView, webView, loadingIndicator, scrollToTopButton, settingsBackdrop, settingsPanel].forEach {
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
            
            settingsBackdrop.topAnchor.constraint(equalTo: view.topAnchor),
            settingsBackdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsBackdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsBackdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            settingsPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            settingsPanel.heightAnchor.constraint(equalToConstant: 280),
            
            scrollToTopButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollToTopButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            scrollToTopButton.widthAnchor.constraint(equalToConstant: 44),
            scrollToTopButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        webView.navigationDelegate = self
        settingsPanel.delegate = self
        
        scrollToTopButton.addTarget(self, action: #selector(scrollToTop), for: .touchUpInside)
        
        // 添加滚动监听
        webView.scrollView.delegate = self
        
        // 添加长按手势
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        webView.addGestureRecognizer(longPress)
        
        // 添加点击手势来关闭设置面板
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideSettings))
        settingsBackdrop.addGestureRecognizer(tapGesture)
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
                :root {
                    --text-color: #000000;
                    --background-color: #FFFFFF;
                    --secondary-text-color: #666666;
                    --link-color: #007AFF;
                    --border-color: #E5E5EA;
                    --max-width: 680px;
                    --paragraph-spacing: 1.8;
                    --font-size: 17px;
                    --font-family: -apple-system, system-ui;
                    --line-height: 1.8;
                    --letter-spacing: 0;
                    --paragraph-indent: 0;
                    --theme-color: #007AFF;
                }
                
                @media (prefers-color-scheme: dark) {
                    :root {
                        --text-color: #FFFFFF;
                        --background-color: #000000;
                        --secondary-text-color: #8E8E93;
                        --link-color: #0A84FF;
                        --border-color: #38383A;
                    }
                }
                
                body {
                    font-family: var(--font-family);
                    font-size: var(--font-size);
                    line-height: var(--line-height);
                    letter-spacing: var(--letter-spacing);
                    padding: 16px;
                    margin: 0 auto;
                    max-width: var(--max-width);
                    color: var(--text-color);
                    background-color: var(--background-color);
                    -webkit-font-smoothing: antialiased;
                    -moz-osx-font-smoothing: grayscale;
                }
                
                p {
                    text-indent: var(--paragraph-indent);
                    margin-bottom: 20px;
                }
                
                h1 {
                    font-size: 26px;
                    font-weight: 700;
                    margin-bottom: 24px;
                    line-height: 1.3;
                }
                
                h2 {
                    font-size: 22px;
                    font-weight: 600;
                    margin-top: 32px;
                    margin-bottom: 16px;
                }
                
                h3 {
                    font-size: 20px;
                    font-weight: 600;
                    margin-top: 24px;
                    margin-bottom: 12px;
                }
                
                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 12px;
                    margin: 24px 0;
                    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
                }
                
                a {
                    color: var(--link-color);
                    text-decoration: none;
                }
                
                blockquote {
                    margin: 20px 0;
                    padding: 12px 24px;
                    border-left: 4px solid var(--border-color);
                    background-color: var(--background-color);
                    font-style: italic;
                }
                
                code {
                    font-family: 'SF Mono', Menlo, monospace;
                    background-color: var(--border-color);
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-size: 14px;
                }
                
                pre {
                    background-color: var(--border-color);
                    padding: 16px;
                    border-radius: 8px;
                    overflow-x: auto;
                }
                
                ul, ol {
                    padding-left: 24px;
                    margin-bottom: 20px;
                }
                
                li {
                    margin-bottom: 8px;
                }
                
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 24px 0;
                }
                
                th, td {
                    border: 1px solid var(--border-color);
                    padding: 12px;
                    text-align: left;
                }
                
                th {
                    background-color: var(--border-color);
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
        settingsBackdrop.isHidden = false
        settingsPanel.isHidden = false
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            self.settingsBackdrop.alpha = 1
            self.settingsPanel.alpha = 1
            self.settingsPanel.transform = .identity
        }
    }
    
    @objc private func hideSettings() {
        UIView.animate(withDuration: 0.2) {
            self.settingsBackdrop.alpha = 0
            self.settingsPanel.alpha = 0
            self.settingsPanel.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            self.settingsBackdrop.isHidden = true
            self.settingsPanel.isHidden = true
        }
    }
    
    @objc private func scrollToTop() {
        webView.scrollView.setContentOffset(.zero, animated: true)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: webView)
            webView.evaluateJavaScript("""
                (function() {
                    var element = document.elementFromPoint(\(point.x), \(point.y));
                    if (element) {
                        var selection = window.getSelection();
                        var range = document.createRange();
                        range.selectNodeContents(element);
                        selection.removeAllRanges();
                        selection.addRange(range);
                        return element.textContent;
                    }
                    return '';
                })()
            """) { result, error in
                if let text = result as? String, !text.isEmpty {
                    self.showTextActionSheet(text)
                }
            }
        }
    }
    
    private func showTextActionSheet(_ text: String) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "复制", style: .default) { _ in
            UIPasteboard.general.string = text
            self.showToast(message: "已复制到剪贴板")
        })
        
        actionSheet.addAction(UIAlertAction(title: "分享", style: .default) { _ in
            let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            self.present(activityVC, animated: true)
        })
        
        actionSheet.addAction(UIAlertAction(title: L("Cancel"), style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    private func showToast(message: String) {
        let toast = UILabel()
        toast.text = message
        toast.textAlignment = .center
        toast.font = .systemFont(ofSize: 14)
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toast.layer.cornerRadius = 20
        toast.clipsToBounds = true
        toast.alpha = 0
        
        view.addSubview(toast)
        toast.translatesAutoresizingMaskIntoConstraints = false
        toast.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40).isActive = true
        toast.heightAnchor.constraint(equalToConstant: 40).isActive = true
        toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        toast.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20).isActive = true
        toast.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20).isActive = true
        
        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 1
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                UIView.animate(withDuration: 0.3, animations: {
                    toast.alpha = 0
                }) { _ in
                    toast.removeFromSuperview()
                }
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
        webView.evaluateJavaScript("""
            document.documentElement.style.setProperty('--font-size', '\(size)px');
        """)
    }
    
    func settingsPanel(_ panel: ArticleSettingsPanel, didSelectFont font: String) {
        webView.evaluateJavaScript("""
            document.documentElement.style.setProperty('--font-family', '\(font)');
        """)
    }
    
    func settingsPanel(_ panel: ArticleSettingsPanel, didChangeLineHeight height: CGFloat) {
        webView.evaluateJavaScript("""
            document.documentElement.style.setProperty('--line-height', '\(height)');
        """)
    }
    
    func settingsPanel(_ panel: ArticleSettingsPanel, didChangeLetterSpacing spacing: CGFloat) {
        webView.evaluateJavaScript("""
            document.documentElement.style.setProperty('--letter-spacing', '\(spacing)px');
        """)
    }
    
    func settingsPanel(_ panel: ArticleSettingsPanel, didChangeParagraphIndent indent: CGFloat) {
        webView.evaluateJavaScript("""
            document.documentElement.style.setProperty('--paragraph-indent', '\(indent)em');
        """)
    }
    
    func settingsPanel(_ panel: ArticleSettingsPanel, didChangeThemeColor color: UIColor) {
        let hexColor = color.hexString
        webView.evaluateJavaScript("""
            document.documentElement.style.setProperty('--theme-color', '#\(hexColor)');
        """)
    }
}

// MARK: - UIScrollViewDelegate
extension ArticleDetailViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let frameHeight = scrollView.frame.height
        
        // 显示/隐藏回到顶部按钮
        UIView.animate(withDuration: 0.3) {
            self.scrollToTopButton.alpha = offsetY > frameHeight ? 1 : 0
        }
    }
} 
