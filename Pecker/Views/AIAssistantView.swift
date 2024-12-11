import UIKit
import SnapKit
import Lottie

class AIAssistantView: UIView {
    // MARK: - Properties
    private let buttonSize: CGFloat = 56
    private let maxExpandedHeight: CGFloat = UIScreen.main.bounds.height * 0.6
    private let minExpandedHeight: CGFloat = 400
    private let expandedWidth: CGFloat = UIScreen.main.bounds.width - 40
    private var isExpanded = false
    private var isThinking = false
    
    private var insights: [AIInsight] = []
    private var tapAction: (() -> Void)?
    
    private var currentExpandedHeight: CGFloat = UIScreen.main.bounds.height * 0.6
    private var initialTouchPoint: CGPoint = .zero
    private var initialHeight: CGFloat = 200
    
    // 添加调整手柄视图
    private let resizeHandleView: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiarySystemFill
        view.layer.cornerRadius = 2.5
        
        // 添加一个更大的触摸区域视图
        let touchArea = UIView()
        touchArea.backgroundColor = .clear // 透明的触摸区域
        view.addSubview(touchArea)
        touchArea.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(-20) // 扩大上部触摸区域
            make.bottom.equalToSuperview().offset(20) // 扩大下部触摸区域
            make.width.equalTo(100) // 扩大左右触摸区域
        }
        
        return view
    }()
    
    // MARK: - UI Elements
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 28
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowOpacity = 0.3 // 增加阴影不透明度
        view.layer.shadowRadius = 20 // 增加阴影范围
        return view
    }()
    
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 28
        
        // 添加内边框
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.separator.cgColor
        
        // 添加内部阴影效果
        let innerShadow = CALayer()
        innerShadow.frame = view.bounds
        innerShadow.shadowColor = UIColor.black.cgColor
        innerShadow.shadowOffset = CGSize(width: 0, height: 2)
        innerShadow.shadowOpacity = 0.1
        innerShadow.shadowRadius = 4
        view.layer.addSublayer(innerShadow)
        
        return view
    }()
    
    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemThinMaterial) // 改用更强的模糊效果
        let view = UIVisualEffectView(effect: blur)
        view.layer.cornerRadius = 28
        view.clipsToBounds = true
        return view
    }()
    
    private let pulseLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.type = .radial
        layer.colors = [
            UIColor.systemPurple.withAlphaComponent(0.2).cgColor,
            UIColor.clear.cgColor
        ]
        layer.startPoint = CGPoint(x: 0.5, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 1)
        return layer
    }()
    
    private let animationView: LottieAnimationView = {
        let animation = LottieAnimationView(name: "ai_pulse")
        animation.loopMode = .loop
        animation.contentMode = .scaleAspectFit
        return animation
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "bird")
        imageView.tintColor = .systemPurple
        imageView.contentMode = .scaleAspectFit
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        imageView.layer.shadowOpacity = 0.1
        imageView.layer.shadowRadius = 4
        return imageView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.alpha = 0
        return view
    }()
    
    private let insightTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.register(AIInsightCell.self, forCellReuseIdentifier: "InsightCell")
        return table
    }()
    
    private let birdNestView: UIView = {
        let view = UIView()
        // 使用渐变背景
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemBackground.withAlphaComponent(0.95).cgColor,
            UIColor.systemBackground.withAlphaComponent(0.8).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // 添加内部装饰
        let decorationLayer = CAShapeLayer()
        decorationLayer.fillColor = UIColor.systemGray5.cgColor
        // 添加一些圆形或波浪形状的装饰
        
        view.layer.cornerRadius = 40
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowOpacity = 0.15
        view.layer.shadowRadius = 8
        return view
    }()
    
    private let birdView: LottieAnimationView = {
        let animation = LottieAnimationView(name: "bird")
        animation.loopMode = .loop
        animation.contentMode = .scaleAspectFit
        animation.transform = CGAffineTransform(scaleX: -1, y: 1)
        return animation
    }()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestures()
        setupTableView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(blurView)
        containerView.addSubview(backgroundView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(contentView)
        contentView.addSubview(insightTableView)
        
        containerView.addSubview(birdNestView)
        birdNestView.addSubview(birdView)
        
        containerView.addSubview(resizeHandleView)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.white.withAlphaComponent(0.3).cgColor,
            UIColor.systemBackground.withAlphaComponent(0.2).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5]
        gradientLayer.cornerRadius = 28
        
        let highlightLayer = CAGradientLayer()
        highlightLayer.colors = [
            UIColor.white.withAlphaComponent(0.2).cgColor,
            UIColor.clear.cgColor
        ]
        highlightLayer.locations = [0.0, 0.5]
        highlightLayer.cornerRadius = 28
        highlightLayer.frame = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize/2)
        
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)
//        backgroundView.layer.addSublayer(highlightLayer)
//        backgroundView.layer.addSublayer(innerShadow)
        
        backgroundView.backgroundColor = .clear
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.size.equalTo(buttonSize)
        }
        
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        insightTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        birdNestView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-40)
            make.centerX.equalToSuperview()
            make.width.equalTo(80)
            make.height.equalTo(40)
        }
        
        birdView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(50)
        }
        
        birdNestView.isHidden = true
        
        resizeHandleView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.width.equalTo(36)
            make.height.equalTo(5)
        }
        resizeHandleView.alpha = 0
        
        layoutIfNeeded()
        gradientLayer.frame = backgroundView.bounds
    }
    
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        containerView.addGestureRecognizer(tap)
        
        let resizePanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleResizePan))
        resizeHandleView.addGestureRecognizer(resizePanGesture)
        resizeHandleView.isUserInteractionEnabled = true
    }
    
    private func setupTableView() {
        insightTableView.delegate = self
        insightTableView.dataSource = self
        insightTableView.backgroundColor = .clear
        insightTableView.isScrollEnabled = true
        insightTableView.showsVerticalScrollIndicator = false
    }
    
    // MARK: - Gesture Handling
    @objc private func handleResizePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: containerView)
        
        switch gesture.state {
        case .began:
            initialHeight = containerView.frame.height
            
        case .changed:
            var newHeight = initialHeight - translation.y
            newHeight = min(max(newHeight, minExpandedHeight), maxExpandedHeight)
            
            // 使用 transform 而不是约束来实现实时拖动
            containerView.snp.updateConstraints { make in
                make.height.equalTo(newHeight)
            }
            
            // 立即更新布局，避免延迟
            containerView.layoutIfNeeded()
            
            // 减少触感反馈的频率
            if abs(translation.y).truncatingRemainder(dividingBy: 50) < 1 {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred(intensity: 0.3)
            }
            
        case .ended, .cancelled:
            // 计算最终高度
            var finalHeight = initialHeight - translation.y
            finalHeight = min(max(finalHeight, minExpandedHeight), maxExpandedHeight)
            self.currentExpandedHeight = finalHeight
            
            // 使用动画平滑过渡到最终高度
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
                self.containerView.snp.updateConstraints { make in
                    make.height.equalTo(finalHeight)
                }
                self.containerView.layoutIfNeeded()
            }
            
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
        default:
            break
        }
    }
    
    // MARK: - Public Methods
    func addInsight(_ insight: AIInsight) {
        insights.append(insight)
        if isExpanded {
            let indexPath = IndexPath(row: insights.count - 1, section: 0)
            insightTableView.insertRows(at: [indexPath], with: .fade)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.insightTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
        showInsightIndicator()
    }
    
    // MARK: - Private Methods
    func startThinking() {
        isThinking = true
        if isExpanded {
            birdView.play()
        }
    }
    
    func stopThinking() {
        isThinking = false
        if isExpanded {
            birdView.stop()
        }
    }
    
    private func startPulseAnimation() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.8
        animation.toValue = 0
        animation.duration = 1.5
        animation.repeatCount = .infinity
        pulseLayer.add(animation, forKey: "pulse")
    }
    
    private func showInsightIndicator() {
        let flash = CABasicAnimation(keyPath: "backgroundColor")
        flash.fromValue = UIColor.systemPurple.withAlphaComponent(0.3).cgColor
        flash.toValue = UIColor.clear.cgColor
        flash.duration = 0.3
        flash.autoreverses = true
        containerView.layer.add(flash, forKey: "flash")
        
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    func expand() {
        guard !isExpanded else { return }
        isExpanded = true
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        self.iconImageView.isHidden = true
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.containerView.snp.updateConstraints { make in
                make.width.equalTo(self.expandedWidth)
                make.height.equalTo(self.currentExpandedHeight)
            }
            self.layoutIfNeeded()
            self.contentView.alpha = 1
            self.iconImageView.alpha = 0
            self.resizeHandleView.alpha = 1
            self.birdNestView.isHidden = false
        }
    }
    
    func collapse() {
        guard isExpanded else { return }
        isExpanded = false
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        birdView.stop()
        self.iconImageView.isHidden = false
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.containerView.snp.updateConstraints { make in
                make.size.equalTo(self.buttonSize)
            }
            self.layoutIfNeeded()
            self.contentView.alpha = 0
            self.iconImageView.alpha = 1
            self.resizeHandleView.alpha = 0
            self.birdNestView.isHidden = true
        }
    }
    
    // MARK: - Gesture Handlers
    @objc private func handleTap() {
        if isExpanded {
            collapse()
        } else {
            expand()
        }
    }
}

// MARK: - UITableViewDataSource
extension AIAssistantView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return insights.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InsightCell", for: indexPath) as! AIInsightCell
        let insight = insights[indexPath.row]
        cell.configure(with: insight)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension AIAssistantView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let insight = insights[indexPath.row]
        insight.action?()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let insight = insights[indexPath.row]
        
        // 计算文本高度
        let titleHeight: CGFloat = 24 // 固定标题高度
        
        let descriptionHeight = insight.description.height(
            withConstrainedWidth: tableView.bounds.width - 76, // 考虑增加的边距
            font: .systemFont(ofSize: 16)
        )
        
        // 返回总高度（上下边距 + 标题高度 + 间距 + 描述文本高度）
        return 16 + titleHeight + 12 + descriptionHeight + 16
    }
}

// MARK: - Models
struct AIInsight {
    let type: InsightType
    let title: String
    let description: String
    let action: (() -> Void)?
    
    enum InsightType {
        case reading
        case listening
        case recommendation
        case summary
        case analysis
        
        var icon: String {
            switch self {
            case .reading: return "book.fill"
            case .listening: return "headphones"
            case .recommendation: return "star.fill"
            case .summary: return "text.alignleft"
            case .analysis: return "chart.bar.fill"
            }
        }
        
        var color: UIColor {
            switch self {
            case .reading: return .systemBlue
            case .listening: return .systemGreen
            case .recommendation: return .systemYellow
            case .summary: return .systemPurple
            case .analysis: return .systemOrange
            }
        }
    }
}

// MARK: - AIInsightCell
class AIInsightCell: UITableViewCell {
    // MARK: - Properties
    private var fullText: String = ""
    private var currentTypingIndex: Int = 0
    private var typingTimer: Timer?
    
    // MARK: - UI Elements
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemPurple
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold) // 增大字号，加粗
        label.textColor = .label
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16) // 增大描述文字
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .left
        label.lineBreakMode = .byWordWrapping
        label.baselineAdjustment = .none
        return label
    }()
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup UI
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        
        // 调整间距和布局
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16) // 增加上边距
            make.leading.equalTo(iconView.snp.trailing).offset(16) // 增加图标和文字间距
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(24) // 增加标题高度
        }
        
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16) // 增加左边距
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(28) // 增大图标尺寸
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12) // 增加标题和描述间距
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-16) // 增加下边距
        }
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0))
        }
    }
    
    // MARK: - Configuration
    func configure(with insight: AIInsight) {
        iconView.image = UIImage(systemName: insight.type.icon)
        iconView.tintColor = insight.type.color
        titleLabel.text = insight.title
        
        // 保存完整文本
        fullText = insight.description
        // 清空描述标签
        descriptionLabel.text = ""
        // 开始打字动画
        startTypingAnimation()
    }
    
    // MARK: - Typing Animation
    private func startTypingAnimation() {
        // 重置状态
        currentTypingIndex = 0
        typingTimer?.invalidate()
        
        // 先设置完整文本但透明度为0
        descriptionLabel.text = fullText
        descriptionLabel.alpha = 0
        
        // 动画显示文本
        UIView.animate(withDuration: 0.3) {
            self.descriptionLabel.alpha = 1
        }
        
        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if self.currentTypingIndex < self.fullText.count {
                let index = self.fullText.index(self.fullText.startIndex, offsetBy: self.currentTypingIndex)
                self.descriptionLabel.text = String(self.fullText[...index])
                self.currentTypingIndex += 1
                
                // 每10个字符触发一次触感反馈
                if self.currentTypingIndex % 10 == 0 {
                    let generator = UIImpactFeedbackGenerator(style: .soft)
                    generator.impactOccurred(intensity: 0.3)
                }
                
                // 如果是标点符号，增加延迟
                if [",", ".", "，", "。", "!", "?", "！", "？"].contains(String(self.fullText[index])) {
                    timer.fireDate = Date().addingTimeInterval(0.2)
                }
            } else {
                timer.invalidate()
                self.typingTimer = nil
                
                // 完成时的触感反馈
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        typingTimer?.invalidate()
        typingTimer = nil
        descriptionLabel.text = ""
    }
    
    // MARK: - Trait Collection Did Change
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            // 更新渐变颜色
            if let gradientLayer = containerView.layer.sublayers?.first as? CAGradientLayer {
                gradientLayer.colors = [
                    UIColor { traitCollection in
                        return traitCollection.userInterfaceStyle == .dark ? 
                            .secondarySystemBackground.withAlphaComponent(0.9) : 
                            .white
                    }.cgColor,
                    UIColor { traitCollection in
                        return traitCollection.userInterfaceStyle == .dark ? 
                            .systemBackground.withAlphaComponent(0.7) : 
                            .systemBackground.withAlphaComponent(0.9)
                    }.cgColor
                ]
            }
        }
    }
}
