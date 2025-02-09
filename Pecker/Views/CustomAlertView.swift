import UIKit

class CustomAlertView: UIView {
    // MARK: - Properties
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let stackView = UIStackView()
    private var actions: [AlertAction] = []
    
    struct AlertAction {
        let title: String
        let handler: (() -> Void)?
    }
    
    // MARK: - Initialization
    init(title: String, message: String) {
        super.init(frame: UIScreen.main.bounds)
        setupView()
        configure(title: title, message: message)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.2)
        
        // Container View - 限制最大高度，避免内容过多时占满屏幕
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // 添加最大高度约束
        let maxHeightConstraint = containerView.heightAnchor.constraint(lessThanOrEqualToConstant: UIScreen.main.bounds.height * 0.7)
        maxHeightConstraint.priority = .required - 1
        maxHeightConstraint.isActive = true
        
        // Add blur effect to container
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(blurView)
        
        // Title Label
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Message Label (if needed)
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)
        
        // Stack View for Actions
        stackView.axis = .vertical
        stackView.spacing = 12  // 增加间距
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)  // 增加边距
        stackView.isLayoutMarginsRelativeArrangement = true
        containerView.addSubview(stackView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container View - 固定在底部
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Message Label
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Stack View
            stackView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // 如果是 iPhone，需要考虑底部安全区域
            containerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func configure(title: String, message: String) {
        titleLabel.text = title
        messageLabel.text = message
        messageLabel.isHidden = message.isEmpty
    }
    
    // MARK: - Public Methods
    func addAction(title: String, handler: (() -> Void)? = nil) {
        let action = AlertAction(title: title, handler: handler)
        actions.append(action)
        
        if actions.count > 1 {
            // Add separator line
            let separator = createSeparator()
            stackView.addArrangedSubview(separator)
        }
        
        let button = createActionButton(with: title, action: action)
        stackView.addArrangedSubview(button)
    }
    
    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return separator
    }
    
    private func createActionButton(with title: String, action: AlertAction) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.backgroundColor = .secondarySystemGroupedBackground
        button.setTitleColor(.tintColor, for: .normal)
        button.heightAnchor.constraint(equalToConstant: 65).isActive = true  // 增加按钮高度
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        
        // 添加按压效果
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
        button.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
        button.tag = actions.count - 1
        
        return button
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.alpha = 0.7
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.alpha = 1.0
        }
    }
    
    @objc private func actionButtonTapped(_ sender: UIButton) {
        hide {
            self.actions[sender.tag].handler?()
        }
    }
    
    // MARK: - Show/Hide Methods
    func show() {
        // Add to key window
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(self)
        }
        
        // Animation
        containerView.transform = CGAffineTransform(translationX: 0, y: 300)
        alpha = 0
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.containerView.transform = .identity
            self.alpha = 1
        }
    }
    
    private func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2) {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: 300)
        } completion: { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
    
    // 添加点击背景关闭的功能
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if !containerView.frame.contains(location) {
            hide()
        }
    }
}
