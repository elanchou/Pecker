import UIKit
import SnapKit
import Lottie

class AIAssistantView: UIView {
    // MARK: - Properties
    private let buttonSize: CGFloat = 56
    private let expandedHeight: CGFloat = 200
    private let expandedWidth: CGFloat = UIScreen.main.bounds.width - 40
    private var isExpanded = false
    private var isThinking = false
    
    private var insights: [AIInsight] = []
    private var tapAction: (() -> Void)?
    
    // MARK: - UI Elements
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 28
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowOpacity = 0.15
        view.layer.shadowRadius = 12
        return view
    }()
    
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 28
        return view
    }()
    
    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
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
    
    private let insightLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        label.text = "正在分析..."
        return label
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
//        containerView.addSubview(insightLabel)
        containerView.addSubview(contentView)
        contentView.addSubview(insightTableView)
        
        containerView.addSubview(birdNestView)
        birdNestView.addSubview(birdView)
        
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
        
        let innerShadow = CALayer()
        innerShadow.frame = backgroundView.bounds
        innerShadow.backgroundColor = UIColor.white.withAlphaComponent(0.1).cgColor
        innerShadow.cornerRadius = 28
        innerShadow.masksToBounds = true
        
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
        
//        insightLabel.snp.makeConstraints { make in
//            make.centerX.equalToSuperview()
//            make.bottom.equalToSuperview().offset(-8)
//        }
        
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
        
        birdNestView.alpha = 0
        birdView.alpha = 0
        
        layoutIfNeeded()
        gradientLayer.frame = backgroundView.bounds
    }
    
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        containerView.addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
    }
    
    private func setupTableView() {
        insightTableView.delegate = self
        insightTableView.dataSource = self
        insightTableView.backgroundColor = .clear
        insightTableView.isScrollEnabled = true
        insightTableView.showsVerticalScrollIndicator = false
    }
    
    // MARK: - Public Methods
    func addInsight(_ insight: AIInsight) {
        insights.append(insight)
        if isExpanded {
            insightTableView.reloadData()
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
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.containerView.snp.updateConstraints { make in
                make.width.equalTo(self.expandedWidth)
                make.height.equalTo(self.expandedHeight)
            }
            self.layoutIfNeeded()
            self.contentView.alpha = 1
            self.iconImageView.alpha = 0
            self.insightLabel.alpha = 0
            
            self.birdNestView.transform = .identity
            self.birdNestView.alpha = 1
            self.birdView.alpha = 1
        } completion: { _ in
            if self.isThinking {
                self.birdView.play()
            }
        }
    }
    
    func collapse() {
        guard isExpanded else { return }
        isExpanded = false
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        birdView.stop()
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.containerView.snp.updateConstraints { make in
                make.size.equalTo(self.buttonSize)
            }
            self.layoutIfNeeded()
            self.contentView.alpha = 0
            self.iconImageView.alpha = 1
            self.insightLabel.alpha = 1
            
            self.birdNestView.transform = CGAffineTransform(translationX: 0, y: 40)
            self.birdNestView.alpha = 0
            self.birdView.alpha = 0
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
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)
        
        switch gesture.state {
        case .changed:
            center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
            gesture.setTranslation(.zero, in: self)
            
        case .ended:
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            var finalX = center.x
            var finalY = center.y
            
            if velocity.x > 500 {
                finalX = screenWidth - 40
            } else if velocity.x < -500 {
                finalX = 40
            } else {
                if center.x > screenWidth / 2 {
                    finalX = screenWidth - 40
                } else {
                    finalX = 40
                }
            }
            
            finalY = max(40, min(screenHeight - 40, finalY))
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2) {
                self.center = CGPoint(x: finalX, y: finalY)
            }
            
        default:
            break
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
    // MARK: - UI Elements
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        
        // 外凸效果的阴影
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 8
        
        // 添加渐变背景
        let gradientLayer = CAGradientLayer()
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
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.cornerRadius = 12
        view.layer.insertSublayer(gradientLayer, at: 0)
        
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
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
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
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0))
        }
        
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-12)
        }
    }
    
    // MARK: - Configuration
    func configure(with insight: AIInsight) {
        iconView.image = UIImage(systemName: insight.type.icon)
        iconView.tintColor = insight.type.color
        titleLabel.text = insight.title
        descriptionLabel.text = insight.description
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
