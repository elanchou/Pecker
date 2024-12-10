import UIKit
import SnapKit
import SDWebImage
import AVFoundation
import RealmSwift

class PodcastPlayerViewController: UIViewController {
    // MARK: - Properties
    private let podcastId: String
    private var content: Content?
    private let audioPlayer = AVPlayer()
    private var timeObserver: Any?
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private let feedLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.circle.fill")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 64)
        ), for: .normal)
        button.tintColor = .systemRed
        return button
    }()
    
    private let timeSlider: UISlider = {
        let slider = UISlider()
        slider.minimumTrackTintColor = .systemRed
        slider.maximumTrackTintColor = .systemGray5
        slider.setThumbImage(UIImage(systemName: "circle.fill")?.withTintColor(.systemRed, renderingMode: .alwaysOriginal), for: .normal)
        return slider
    }()
    
    private let currentTimeLabel: UILabel = {
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
    
    private let speedButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("1.0x", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        return button
    }()
    
    private let backwardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "gobackward.15"), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    private let forwardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "goforward.30"), for: .normal)
        button.tintColor = .label
        return button
    }()
    
    // MARK: - Init
    init(podcastId: String) {
        self.podcastId = podcastId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadContent()
        setupGestures()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let observer = timeObserver {
            audioPlayer.removeTimeObserver(observer)
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 设置导航栏
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.down"),
            style: .plain,
            target: self,
            action: #selector(dismissVC)
        )
        
        // 添加分享按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareContent)
        )
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // 添加子视图
        [coverImageView, titleLabel, feedLabel, dateLabel].forEach {
            contentView.addSubview($0)
        }
        
        // 创建播放控制容器
        let controlsContainer = UIView()
        contentView.addSubview(controlsContainer)
        
        // 添加播放控制
        [currentTimeLabel, timeSlider, durationLabel].forEach {
            controlsContainer.addSubview($0)
        }
        
        // 创建按钮容器
        let buttonStack = UIStackView(arrangedSubviews: [backwardButton, playButton, forwardButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 32
        buttonStack.alignment = .center
        controlsContainer.addSubview(buttonStack)
        
        controlsContainer.addSubview(speedButton)
        
        // 设置约束
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        coverImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(280)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(coverImageView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        feedLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(feedLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        controlsContainer.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-32)
        }
        
        currentTimeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.bottom.equalTo(timeSlider.snp.top).offset(-8)
        }
        
        durationLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.bottom.equalTo(timeSlider.snp.top).offset(-8)
        }
        
        timeSlider.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(buttonStack.snp.top).offset(-24)
        }
        
        buttonStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(speedButton.snp.top).offset(-24)
        }
        
        speedButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        // 添加事件处理
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        timeSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        backwardButton.addTarget(self, action: #selector(backwardButtonTapped), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(forwardButtonTapped), for: .touchUpInside)
        speedButton.addTarget(self, action: #selector(speedButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Data Loading
    private func loadContent() {
        do {
            let realm = try Realm()
            if let content = realm.object(ofType: Content.self, forPrimaryKey: podcastId) {
                self.content = content
                configure(with: content)
            }
        } catch {
            print("Error loading content: \(error)")
        }
    }
    
    private func configure(with content: Content) {
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
        timeSlider.value = Float(content.playbackPosition / content.duration)
        currentTimeLabel.text = formatTime(content.playbackPosition)
        
        updatePlayButton(isPlaying: content.isPlaying)
    }
    
    // MARK: - Actions
    @objc private func dismissVC() {
        dismiss(animated: true)
    }
    
    @objc private func shareContent() {
        guard let content = content,
              let url = content.validURL else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        present(activityVC, animated: true)
    }
    
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
    }
    
    @objc private func sliderValueChanged() {
        guard let content = content else { return }
        let time = Double(timeSlider.value) * content.duration
        audioPlayer.seek(to: CMTime(seconds: time, preferredTimescale: 1))
        currentTimeLabel.text = formatTime(time)
    }
    
    @objc private func backwardButtonTapped() {
        let currentTime = CMTimeGetSeconds(audioPlayer.currentTime())
        let newTime = max(0, currentTime - 15)
        audioPlayer.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
    }
    
    @objc private func forwardButtonTapped() {
        guard let duration = audioPlayer.currentItem?.duration.seconds else { return }
        let currentTime = CMTimeGetSeconds(audioPlayer.currentTime())
        let newTime = min(duration, currentTime + 30)
        audioPlayer.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
    }
    
    @objc private func speedButtonTapped() {
        let speeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
        let currentSpeed = audioPlayer.rate
        let currentIndex = speeds.firstIndex(of: currentSpeed) ?? 2
        let nextIndex = (currentIndex + 1) % speeds.count
        let newSpeed = speeds[nextIndex]
        
        audioPlayer.rate = newSpeed
        speedButton.setTitle("\(newSpeed)x", for: .normal)
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
        timeSlider.value = Float(progress)
        currentTimeLabel.text = formatTime(time.seconds)
        
        // 更新播放进度
        do {
            let realm = try Realm()
            try realm.write {
                content.playbackPosition = time.seconds
            }
        } catch {
            print("Error updating playback position: \(error)")
        }
    }
    
    private func updatePlayButton(isPlaying: Bool) {
        let imageName = isPlaying ? "pause.circle.fill" : "play.circle.fill"
        playButton.setImage(UIImage(systemName: imageName)?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 64)
        ), for: .normal)
    }
    
    // MARK: - Gestures
    private func setupGestures() {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissVC))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}
