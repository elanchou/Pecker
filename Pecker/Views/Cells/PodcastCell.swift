import UIKit
import AVFoundation
import SDWebImage
import SnapKit

class PodcastCell: UICollectionViewCell {
    // MARK: - Properties
    private var content: Content?
    private let audioPlayer = AVPlayer()
    private var timeObserver: Any?
    weak var delegate: PodcastCellDelegate?
    
    // MARK: - UI Elements
    private let containerView = UIView()
    private let contentStackView = UIStackView()
    
    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        return label
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
        return label
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        button.tintColor = AppTheme.primary
        button.contentMode = .scaleAspectFit
        return button
    }()
    
    private let progressSlider: UISlider = {
        let slider = UISlider()
        slider.minimumTrackTintColor = AppTheme.primary
        slider.maximumTrackTintColor = .systemGray5
        slider.setThumbImage(UIImage(systemName: "circle.fill")?.withTintColor(AppTheme.primary, renderingMode: .alwaysOriginal), for: .normal)
        return slider
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "00:00"
        return label
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "--:--"
        return label
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
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        contentView.addSubview(containerView)
        containerView.addSubview(contentStackView)
        
        // 创建水平主布局
        contentStackView.axis = .horizontal
        contentStackView.spacing = 12
        contentStackView.alignment = .top
        
        // 创建右侧垂直布局
        let rightStackView = UIStackView()
        rightStackView.axis = .vertical
        rightStackView.spacing = 8
        
        // 添加左侧封面图片
        contentStackView.addArrangedSubview(coverImageView)
        
        // 添加右侧内容
        contentStackView.addArrangedSubview(rightStackView)
        
        // 将标题、Feed名称等添加到右侧布局
        [titleLabel, feedLabel].forEach {
            rightStackView.addArrangedSubview($0)
        }
        
        // 添加播放控制视图到右侧布局
        let controlStack = UIStackView()
        controlStack.axis = .horizontal
        controlStack.spacing = 8
        controlStack.alignment = .center
        
        [playButton, progressSlider, timeLabel, durationLabel].forEach {
            controlStack.addArrangedSubview($0)
        }
        
        rightStackView.addArrangedSubview(controlStack)
        
        // 修改约束
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0))
        }
        
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 修改封面图片尺寸
        coverImageView.snp.makeConstraints { make in
            make.width.height.equalTo(100) // 调整为更合适的尺寸
        }
        
        // 让右侧堆栈视图填充剩余空间
        rightStackView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(coverImageView)
        }
        
        playButton.snp.makeConstraints { make in
            make.width.height.equalTo(44) // 调整播放按钮尺寸
        }
        
        [timeLabel, durationLabel].forEach { label in
            label.snp.makeConstraints { make in
                make.width.equalTo(50)
            }
        }
        
        // 添加事件处理
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        progressSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
    }
    
    // MARK: - Configuration
    func configure(with content: Content) {
        self.content = content
        
        titleLabel.text = content.title
        feedLabel.text = content.feed.first?.title
        dateLabel.text = formatDate(content.publishDate)
        
        // 设置封面图片
        if let imageURL = content.imageURLs.first,
           let url = URL(string: imageURL) {
            coverImageView.sd_setImage(with: url)
        }
        
        // 设置音频
        if let audioURL = content.audioURL,
           let url = URL(string: audioURL) {
            let playerItem = AVPlayerItem(url: url)
            audioPlayer.replaceCurrentItem(with: playerItem)
            setupTimeObserver()
        }
        
        // 设置时长
        durationLabel.text = formatTime(content.duration)
        
        // 恢复播放进度
        progressSlider.value = Float(content.playbackPosition / content.duration)
        timeLabel.text = formatTime(content.playbackPosition)
        
        updatePlayButton(isPlaying: content.isPlaying)
    }
    
    func stopPlaying() {
        audioPlayer.pause()
        content?.isPlaying = false
        updatePlayButton(isPlaying: false)
    }
    
    // MARK: - Actions
    @objc private func playButtonTapped() {
        guard let content = content else { return }
        
        if content.isPlaying {
            audioPlayer.pause()
        } else {
            if content.playbackPosition > 0 {
                audioPlayer.seek(to: CMTime(seconds: content.playbackPosition, preferredTimescale: 1))
            }
            audioPlayer.play()
        }
        
        content.isPlaying.toggle()
        updatePlayButton(isPlaying: content.isPlaying)
        delegate?.podcastCell(self, didChangePlayingState: content.isPlaying)
    }
    
    @objc private func sliderValueChanged() {
        guard let content = content else { return }
        let time = Double(progressSlider.value) * content.duration
        audioPlayer.seek(to: CMTime(seconds: time, preferredTimescale: 1))
        timeLabel.text = formatTime(time)
    }
    
    private func setupTimeObserver() {
        timeObserver = audioPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            self?.updateProgress(time: time)
        }
    }
    
    private func updateProgress(time: CMTime) {
        guard let content = content,
              let duration = audioPlayer.currentItem?.duration.seconds,
              duration.isFinite else { return }
        
        let progress = time.seconds / duration
        progressSlider.value = Float(progress)
        timeLabel.text = formatTime(time.seconds)
//        content.playbackPosition = time.seconds
    }
    
    private func updatePlayButton(isPlaying: Bool) {
        let imageName = isPlaying ? "pause.circle.fill" : "play.circle.fill"
        playButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        audioPlayer.pause()
        audioPlayer.replaceCurrentItem(with: nil)
        if let observer = timeObserver {
            audioPlayer.removeTimeObserver(observer)
        }
        content?.isPlaying = false
    }
    
    // MARK: - Gestures
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
}

// MARK: - UIContextMenuInteractionDelegate
extension PodcastCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let content = content else { return nil }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let toggleRead = UIAction(
                title: content.isRead ? "标记为未读" : "标记为已读",
                image: UIImage(systemName: content.isRead ? "circle" : "circle.fill")
            ) { _ in
                Task {
                    await content.markAsRead()
                }
            }
            
            let toggleFavorite = UIAction(
                title: content.isFavorite ? "取消收藏" : "收藏",
                image: UIImage(systemName: content.isFavorite ? "star.fill" : "star")
            ) { [weak self] _ in
                Task {
                    await content.toggleFavorite()
                }
            }
            
            let share = UIAction(
                title: "分享",
                image: UIImage(systemName: "square.and.arrow.up")
            ) { [weak self] _ in
                guard let url = content.validURL else { return }
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
}

protocol PodcastCellDelegate: AnyObject {
    func podcastCell(_ cell: PodcastCell, didChangePlayingState isPlaying: Bool)
}
