import UIKit
import RealmSwift
import SDWebImage
import SnapKit

class ArticleCell: UICollectionViewCell {
    // MARK: - Properties
    weak var delegate: ArticleCellDelegate?
    private var article: Article?
    private var isExpanded = false
    
    // MARK: - UI Elements
    private let containerView = UIView()
    private let contentStackView = UIStackView()
    private let textStackView = UIStackView()
    private let metaStackView = UIStackView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.numberOfLines = 2
        return label
    }()
    
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 4
        return imageView
    }()
    
    private let feedLabel = UILabel()
    private let dateLabel = UILabel()
    private let unreadIndicator = UIView()
    private let aiButton = UIButton(type: .system)
    private let favoriteIcon = UIImageView()
    private let summaryView = AISummaryView()
    
    private var containerBottomConstraint: NSLayoutConstraint?
    private var summaryHeightConstraint: NSLayoutConstraint?
    
    private let defaultHeight: CGFloat = 130
    private let expandedHeight: CGFloat = 290 // 130 + 160 (summary height)
    
    private let loadingView = LoadingBirdView()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        setupBasicAppearance()
        setupStackViews()
        setupMetaViews()
        setupSummaryView()
        setupConstraints()
        
        contentView.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.center.equalTo(summaryView)
            make.size.equalTo(120)
        }
    }
    
    private func setupBasicAppearance() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        containerView.backgroundColor = .clear
    }
    
    private func setupStackViews() {
        contentStackView.axis = .horizontal
        contentStackView.spacing = 16
        contentStackView.alignment = .top
        
        textStackView.axis = .vertical
        textStackView.spacing = 8
        
        metaStackView.axis = .horizontal
        metaStackView.spacing = 12
        metaStackView.alignment = .center
        
        contentView.addSubview(containerView)
        containerView.addSubview(contentStackView)
        
        // 先添加文本堆栈
        contentStackView.addArrangedSubview(textStackView)
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(metaStackView)
        
        // 再添加缩略图
        contentStackView.addArrangedSubview(thumbnailImageView)
        
        // 添加元数据视图
        [unreadIndicator, feedLabel, dateLabel, UIView(), aiButton, favoriteIcon].forEach {
            metaStackView.addArrangedSubview($0)
        }
        
        // 添加 summary 视图
        contentView.addSubview(summaryView)
    }
    
    private func setupMetaViews() {
        feedLabel.font = .systemFont(ofSize: 13)
        feedLabel.textColor = .secondaryLabel
        
        dateLabel.font = .systemFont(ofSize: 13)
        dateLabel.textColor = .secondaryLabel
        
        unreadIndicator.backgroundColor = .systemBlue
        unreadIndicator.layer.cornerRadius = 2
        unreadIndicator.setContentHuggingPriority(.required, for: .horizontal)
        unreadIndicator.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        aiButton.setImage(UIImage(systemName: "sparkles"), for: .normal)
        aiButton.tintColor = .systemPurple
        aiButton.addTarget(self, action: #selector(aiButtonTapped), for: .touchUpInside)
        
        favoriteIcon.image = UIImage(systemName: "star.fill")
        favoriteIcon.tintColor = .systemYellow
        favoriteIcon.contentMode = .scaleAspectFit
        
        [unreadIndicator, feedLabel, dateLabel, UIView(), aiButton, favoriteIcon].forEach {
            metaStackView.addArrangedSubview($0)
        }
    }
    
    private func setupSummaryView() {
        summaryView.alpha = 0
        summaryView.isHidden = true
        contentView.addSubview(summaryView)
    }
    
    private func setupConstraints() {
        [containerView, contentStackView, thumbnailImageView, summaryView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // 主容器约束
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(defaultHeight)
        }
        
        // 内容堆栈约束
        contentStackView.snp.makeConstraints { make in
            make.edges.equalTo(containerView).inset(UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0))
        }
        
        // 缩略图约束
        thumbnailImageView.snp.makeConstraints { make in
            make.width.equalTo(140)
            make.height.equalTo(85)
            make.trailing.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        // 文本堆栈约束
        textStackView.snp.makeConstraints { make in
            make.height.lessThanOrEqualTo(containerView).offset(-32)
        }
        
        // 未读指示器约束
        unreadIndicator.snp.makeConstraints { make in
            make.leading.equalTo(textStackView)
            make.width.height.equalTo(4)
        }
        
        // AI 按钮约束
        aiButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        
        // Summary 视图约束
        summaryView.snp.makeConstraints { make in
            make.top.equalTo(containerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(160)
            make.bottom.equalToSuperview().priority(.high)
        }
    }
    
    // MARK: - Configuration
    func configure(with article: Article, isExpanded: Bool = false) {
        self.article = article
        self.isExpanded = isExpanded
        
        titleLabel.text = article.title
        feedLabel.text = article.feed.first?.title
        dateLabel.text = formatDate(article.publishDate)
        unreadIndicator.isHidden = article.isRead
        favoriteIcon.isHidden = !article.isFavorite
        
        configureImage(with: article)
        
        // 更新 summaryView 态
        if isExpanded {
            summaryView.isHidden = false
            summaryView.alpha = 1
            if let summary = article.aiSummary {
                summaryView.startTyping(summary)
            }
        } else {
            summaryView.isHidden = true
            summaryView.alpha = 0
            summaryView.stopTyping()
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    private func configureImage(with article: Article) {
        if let imageURL = article.imageURLs.first,
           let url = URL(string: imageURL) {
            thumbnailImageView.isHidden = false
            thumbnailImageView.sd_setImage(
                with: url,
                placeholderImage: nil,
                options: [.retryFailed, .progressiveLoad, .scaleDownLargeImages],
                context: nil  // 移除 thumbnailPixelSize 以使用原图
            )
        } else {
            thumbnailImageView.isHidden = true
        }
    }
    
    // MARK: - Actions
    func showSummary(_ summary: String) {
        summaryView.isHidden = false
        summaryView.alpha = 0
        loadingView.startLoading()
        
        // 更新约束
        contentView.snp.updateConstraints { make in
            make.bottom.equalTo(summaryView.snp.bottom).offset(8)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.summaryView.alpha = 1
            self.layoutIfNeeded()
        } completion: { _ in
            self.loadingView.stopLoading {
                self.summaryView.startTyping(summary)
            }
        }
    }
    
    func hideSummary() {
        // 更新约束
        contentView.snp.updateConstraints { make in
            make.bottom.equalTo(containerView.snp.bottom).offset(8)
        }
        
        UIView.animate(withDuration: 0.2) {
            self.summaryView.alpha = 0
            self.layoutIfNeeded()
        } completion: { _ in
            self.summaryView.isHidden = true
            self.summaryView.stopTyping()
        }
    }
    
    @objc private func aiButtonTapped() {
        guard let article = article else { return }
        delegate?.articleCell(self, didTapAIButton: article)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.sd_cancelCurrentImageLoad()
        thumbnailImageView.image = nil
        summaryView.stopTyping()
        summaryView.isHidden = true
        summaryView.alpha = 0
        isExpanded = false
    }
    
    private func setupGestures() {
        // 添加长按手势
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        contentView.addGestureRecognizer(longPress)
        
        // 添加上下文菜单
        let interaction = UIContextMenuInteraction(delegate: self)
        contentView.addInteraction(interaction)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            // 触感反馈
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        let height = summaryView.isHidden ? defaultHeight : expandedHeight
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        let targetHeight = isExpanded ? expandedHeight : defaultHeight
        
        // 设置新的高度
        attributes.frame.size.height = targetHeight
        return attributes
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

// MARK: - UIContextMenuInteractionDelegate
extension ArticleCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let article = article else { return nil }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let toggleRead = UIAction(
                title: article.isRead ? "标记为未读" : "标记为已读",
                image: UIImage(systemName: article.isRead ? "circle" : "circle.fill")
            ) { [weak self] _ in
                Task {
                    await article.markAsRead()
                }
                self?.unreadIndicator.isHidden = article.isRead
            }
            
            let toggleFavorite = UIAction(
                title: article.isFavorite ? "取消收藏" : "收藏",
                image: UIImage(systemName: article.isFavorite ? "star.fill" : "star")
            ) { [weak self] _ in
                Task {
                    await article.toggleFavorite()
                }
                self?.favoriteIcon.isHidden = !article.isFavorite
            }
            
            let share = UIAction(
                title: "分享",
                image: UIImage(systemName: "square.and.arrow.up")
            ) { [weak self] _ in
                guard let url = article.validURL else { return }
                let activityVC = UIActivityViewController(
                    activityItems: [url],
                    applicationActivities: nil
                )
                
                if let windowScene = self?.window?.windowScene,
                   let viewController = windowScene.windows.first?.rootViewController {
                    viewController.present(activityVC, animated: true)
                }
            }
            
            return UIMenu(title: "", children: [toggleRead, toggleFavorite, share])
        }
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        // 点击预览时的处理
        animator.addCompletion { [weak self] in
            guard let article = self?.article else { return }
            let detailVC = ArticleDetailViewController(articleId: article.id)
            if let windowScene = self?.window?.windowScene,
               let navigationController = windowScene.windows.first?.rootViewController as? UINavigationController {
                navigationController.pushViewController(detailVC, animated: true)
            }
        }
    }
}

protocol ArticleCellDelegate: AnyObject {
    func articleCell(_ cell: ArticleCell, didTapAIButton article: Article)
} 
