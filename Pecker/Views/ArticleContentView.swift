import UIKit
import WebKit
import SwiftSoup
import SDWebImage

class ArticleContentView: UIView {
    // MARK: - Properties
    private let webView: WKWebView
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private var article: Content?
    private var imageCache = NSCache<NSString, UIImage>()
    
    // MARK: - Init
    override init(frame: CGRect) {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let script = WKUserScript(
            source: """
                document.addEventListener('DOMContentLoaded', function() {
                    document.documentElement.style.webkitTouchCallout = 'none';
                    document.documentElement.style.webkitUserSelect = 'none';
                });
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(script)
        
        webView = WKWebView(frame: .zero, configuration: config)
        super.init(frame: frame)
        
        setupUI()
        setupWebView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        [webView, loadingIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func setupWebView() {
        webView.navigationDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = true
        
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshContent), for: .valueChanged)
        webView.scrollView.refreshControl = refresh
    }
    
    // MARK: - Public Methods
    func load(article: Content) {
        self.article = article
        loadingIndicator.startAnimating()
        
        Task {
            do {
                let content = try await processContent(article)
                let html = generateHTML(with: content)
                await MainActor.run {
                    webView.loadHTMLString(html, baseURL: nil)
                }
            } catch {
                print("Error processing content: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    private func processContent(_ article: Content) async throws -> ProcessedContent {
        let doc = try SwiftSoup.parse(article.body)
        
        // 清理文档
        try cleanDocument(doc)
        
        // 提取主要内容
        let mainContent = try extractMainContent(doc)
        
        // 处理图片
        let processedImages = try await processImages(mainContent)
        
        // 格式化内容
        let formattedContent = try formatContent(mainContent)
        
        return ProcessedContent(
            title: article.title,
            content: formattedContent,
            images: processedImages,
            date: article.publishDate,
            source: article.feed.first?.title ?? "",
            originalUrl: article.url
        )
    }
    
    private func cleanDocument(_ doc: Document) throws {
        // 移除不需要的元素
        try doc.select("""
            script, style, iframe, nav, footer, header, aside,
            [class*="nav"], [class*="menu"], [class*="sidebar"],
            [class*="banner"], [class*="ad"], [class*="social"],
            [class*="related"], [class*="comment"]
        """).remove()
        
        // 清理属性
        for element in try doc.getAllElements() {
            try element.removeAttr("onclick")
                      .removeAttr("style")
                      .removeAttr("class")
                      .removeAttr("id")
        }
    }
    
    private func extractMainContent(_ doc: Document) throws -> Element {
        // 1. 首先尝试常见的内容容器选择器
        let selectors = [
            "article", ".article", ".post", ".content", ".entry-content",
            "#article-content", "article .content", ".post-content",
            ".article-content", ".main-content", ".single-content",
            ".article-body", ".entry", ".blog-post"
        ]
        
        for selector in selectors {
            if let element = try doc.select(selector).first() {
                if try isValidContent(element) {
                    return element
                }
            }
        }
        
        // 2. 如���没找到，尝试查找最长的文本块
        let candidates = try doc.select("div, section, article")
        var bestElement = doc.body() ?? doc
        var maxLength = 0
        
        for element in candidates {
            let text = try element.text()
            let valid = try isValidContent(element)
            if text.count > maxLength && valid {
                maxLength = text.count
                bestElement = element
            }
        }
        
        // 3. 如果内容太短，返回整个 body
        if maxLength < 100 {
            return doc.body() ?? doc
        }
        
        return bestElement
    }
    
    private func isValidContent(_ element: Element) throws -> Bool {
        let text = try element.text()
        let links = try element.select("a")
        let linkText = try links.text()
        
        // 检查文本长度
        guard text.count >= 100 else { return false }
        
        // 检查链接密度
        let linkDensity = Double(linkText.count) / Double(text.count)
        guard linkDensity < 0.5 else { return false }
        
        // 检查段落数量
        let paragraphs = try element.select("p")
        guard paragraphs.count >= 2 else { return false }
        
        return true
    }
    
    private func processImages(_ element: Element) async throws -> [ProcessedImage] {
        var processedImages: [ProcessedImage] = []
        let images = try element.select("img")
        
        for img in images {
            guard let src = try? img.attr("src"),
                  let url = URL(string: src) else { continue }
            
            // 使用 SDWebImage 预加载图片
            SDWebImagePrefetcher.shared.prefetchURLs([url])
            
            // 添加延迟加载属性
            try img.attr("data-original-src", src)
            try img.attr("src", "")
            try img.addClass("lazy-load")
            
            // 获取图片尺寸
            if let imageSize = try await getImageSize(from: url) {
                processedImages.append(ProcessedImage(url: url, size: imageSize))
            }
        }
        
        return processedImages
    }
    
    private func getImageSize(from url: URL) async throws -> CGSize? {
        return try await withCheckedThrowingContinuation { continuation in
            SDWebImageManager.shared.loadImage(
                with: url,
                options: [.retryFailed, .progressiveLoad],
                progress: nil
            ) { image, _, error, _, _, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: image?.size)
            }
        }
    }
    
    private func formatContent(_ element: Element) throws -> String {
        // 格式化段落
        for p in try element.select("p") {
            try p.addClass("article-paragraph")
        }
        
        // 格式化标题
        for i in 1...6 {
            for h in try element.select("h\(i)") {
                try h.addClass("article-heading-\(i)")
            }
        }
        
        // 格式化引用
        for blockquote in try element.select("blockquote") {
            try blockquote.addClass("elegant-quote")
        }
        
        // 格式化代码块
        for pre in try element.select("pre") {
            try pre.addClass("code-block")
            if let code = try pre.select("code").first() {
                try code.addClass("language-\(code.className())")
            }
        }
        
        return try element.html()
    }
    
    private func generateHTML(with content: ProcessedContent) -> String {
        // ... HTML 模板保持不变 ...
        // 添加图片延迟加载脚本
        let lazyLoadScript = """
            function loadImage(img) {
                const src = img.getAttribute('data-original-src');
                if (src) {
                    img.src = src;
                    img.removeAttribute('data-original-src');
                    img.classList.remove('lazy-load');
                }
            }
            
            const observer = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        loadImage(entry.target);
                        observer.unobserve(entry.target);
                    }
                });
            });
            
            document.querySelectorAll('.lazy-load').forEach(img => {
                observer.observe(img);
            });
        """
        
        // 将脚本添加到 HTML 模板中
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no">
            <style>
                :root {
                    color-scheme: light dark;
                }
                
                body {
                    font-family: -apple-system, system-ui;
                    line-height: 1.6;
                    padding: 20px;
                    margin: 0;
                    font-size: 16px;
                    color: var(--text-color);
                    background-color: var(--background-color);
                }
                
                @media (prefers-color-scheme: light) {
                    :root {
                        --text-color: #000000;
                        --background-color: #FFFFFF;
                        --quote-background: #f7f7f7;
                        --link-color: #007AFF;
                    }
                }
                
                @media (prefers-color-scheme: dark) {
                    :root {
                        --text-color: #FFFFFF;
                        --background-color: #000000;
                        --quote-background: #1C1C1E;
                        --link-color: #0A84FF;
                    }
                }
                
                .article-header {
                    margin-bottom: 24px;
                }
                
                .article-title {
                    font-size: 24px;
                    font-weight: bold;
                    margin-bottom: 8px;
                }
                
                .article-meta {
                    font-size: 14px;
                    color: var(--secondary-text-color);
                    margin-bottom: 16px;
                }
                
                .article-content {
                    font-size: 16px;
                }
                
                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 8px;
                    margin: 16px 0;
                }
                
                .elegant-quote {
                    margin: 20px 0;
                    padding: 16px;
                    background-color: var(--quote-background);
                    border-left: 4px solid var(--link-color);
                    border-radius: 4px;
                }
                
                pre {
                    background-color: var(--quote-background);
                    padding: 16px;
                    border-radius: 8px;
                    overflow-x: auto;
                }
                
                code {
                    font-family: ui-monospace, monospace;
                    font-size: 14px;
                }
                
                a {
                    color: var(--link-color);
                    text-decoration: none;
                }
                
                p {
                    margin: 16px 0;
                }
                
                .image-container {
                    position: relative;
                    width: 100%;
                    margin: 16px 0;
                }
                
                .image-container img {
                    width: 100%;
                    height: auto;
                    transition: transform 0.3s ease;
                }
                
                .image-container:active img {
                    transform: scale(0.98);
                }
                
                .view-original {
                    display: block;
                    margin: 20px auto;
                    padding: 12px 24px;
                    background-color: var(--link-color);
                    color: white;
                    border-radius: 8px;
                    text-align: center;
                    font-weight: 600;
                    text-decoration: none;
                    transition: opacity 0.3s;
                }
                
                .view-original:active {
                    opacity: 0.8;
                }
            </style>
            <script>\(lazyLoadScript)</script>
        </head>
        <body>
            <div class="article-header">
                <div class="article-title">\(content.title)</div>
                <div class="article-meta">
                    <span>\(content.source)</span> · <span>\(formatDate(content.date))</span>
                </div>
            </div>
            <div class="article-content">
                \(content.content)
                <a href="\(content.originalUrl)" class="view-original">查看原文</a>
            </div>
            <script>
                document.addEventListener('DOMContentLoaded', function() {
                    // 处理图片点击
                    document.querySelectorAll('img').forEach(function(img) {
                        img.addEventListener('click', function() {
                            window.webkit.messageHandlers.imageClicked.postMessage(this.src);
                        });
                    });
                    
                    // 处理链接点击
                    document.querySelectorAll('a').forEach(function(link) {
                        link.addEventListener('click', function(e) {
                            e.preventDefault();
                            window.webkit.messageHandlers.linkClicked.postMessage(this.href);
                        });
                    });
                    
                    // 处理查看原文点击
                    document.querySelector('.view-original').addEventListener('click', function(e) {
                        e.preventDefault();
                        window.webkit.messageHandlers.viewOriginal.postMessage(this.href);
                    });
                });
            </script>
        </body>
        </html>
        """
    }
    
    @objc private func refreshContent() {
        if let article = article {
            load(article: article)
        }
    }
}

// MARK: - WKNavigationDelegate
extension ArticleContentView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
        webView.scrollView.refreshControl?.endRefreshing()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
        webView.scrollView.refreshControl?.endRefreshing()
    }
}

// MARK: - Supporting Types
private struct ProcessedContent {
    let title: String
    let content: String
    let images: [ProcessedImage]
    let date: Date
    let source: String
    let originalUrl: String
}

private struct ProcessedImage {
    let url: URL
    let size: CGSize
} 
