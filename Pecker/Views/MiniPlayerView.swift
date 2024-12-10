import UIKit
import SnapKit
import SDWebImage

class MiniPlayerView: UIView {
    // MARK: - Properties
    private var content: Content?
    private let coverSize: CGFloat = 40
    
    // MARK: - UI Elements
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        // 添加顶部分割线
        let separator = UIView()
        separator.backgroundColor = .separator
        view.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1/UIScreen.main.scale) // 1px 分割线
        }
        return view
    }()
    
    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .systemRed
        progress.trackTintColor = .systemGray5
        return progress
    }()
    
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
        backgroundColor = .systemBackground
        
        // 设置固定高度
        snp.makeConstraints { make in
            make.height.equalTo(60).priority(.required)
        }
        
        addSubview(containerView)
        containerView.addSubview(coverImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(playButton)
        containerView.addSubview(progressView)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        coverImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(coverSize)
        }
        
        playButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        containerView.addSubview(textStack)
        
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(coverImageView.snp.trailing).offset(12)
            make.trailing.equalTo(playButton.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
        }
        
        progressView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(2)
        }
        
        // 添加事件处理
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    func configure(with content: Content) {
        self.content = content
        
        titleLabel.text = content.title
        subtitleLabel.text = content.feed.first?.title
        
        // 设置封面图片
        if let imageURL = content.imageURLs.first,
           let url = URL(string: imageURL) {
            coverImageView.sd_setImage(with: url)
        }
        
        // 更新播放按钮状态
        updatePlayButton(isPlaying: content.isPlaying)
        
        // 更新进度
        progressView.progress = Float(content.playbackPosition / content.duration)
    }
    
    private func updatePlayButton(isPlaying: Bool) {
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    // MARK: - Actions
    @objc private func playButtonTapped() {
        guard let content = content else { return }
        content.isPlaying.toggle()
        updatePlayButton(isPlaying: content.isPlaying)
        
        // 触感反馈
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // MARK: - Gestures
    private func setupGestures() {
        // 添加点击手势
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        containerView.addGestureRecognizer(tap)
        
        // 添加上下文菜单
        let interaction = UIContextMenuInteraction(delegate: self)
        containerView.addInteraction(interaction)
    }
    
    @objc private func handleTap() {
        guard let content = content else { return }
        // 打开播放详情页面
        if let viewController = parentViewController {
            let detailVC = PodcastPlayerViewController(podcastId: content.id)
            let nav = UINavigationController(rootViewController: detailVC)
            viewController.present(nav, animated: true)
        }
    }
}

// MARK: - UIContextMenuInteractionDelegate
extension MiniPlayerView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let content = content else { return nil }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let share = UIAction(
                title: "分享",
                image: UIImage(systemName: "square.and.arrow.up")
            ) { [weak self] _ in
                guard let url = content.validURL else { return }
                let activityVC = UIActivityViewController(
                    activityItems: [url],
                    applicationActivities: nil
                )
                
                if let viewController = self?.parentViewController {
                    viewController.present(activityVC, animated: true)
                }
            }
            
            let favorite = UIAction(
                title: content.isFavorite ? "取消收藏" : "收藏",
                image: UIImage(systemName: content.isFavorite ? "star.fill" : "star")
            ) { _ in
                Task {
                    await content.toggleFavorite()
                }
            }
            
            return UIMenu(title: "", children: [share, favorite])
        }
    }
}

// MARK: - Helper
private extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
} 
