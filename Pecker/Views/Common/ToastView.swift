import UIKit
import SnapKit

class ToastView: UIView {
    // MARK: - Types
    enum Style {
        case success
        case failure
        case info
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .failure: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var tintColor: UIColor {
            switch self {
            case .success: return .systemGreen
            case .failure: return .systemRed
            case .info: return .systemBlue
            }
        }
    }
    
    // MARK: - UI Components
    private let containerView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let view = UIVisualEffectView(effect: blurEffect)
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    // MARK: - Properties
    static let shared = ToastView()
    private var hideTimer: Timer?
    
    // MARK: - Initialization
    private override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        addSubview(containerView)
        containerView.contentView.addSubview(stackView)
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(messageLabel)
        
        containerView.snp.makeConstraints { make in
            make.size.equalTo(120)
            make.center.equalToSuperview()
        }
        
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(32)
        }
    }
    
    // MARK: - Public Methods
    static func show(
        _ message: String,
        style: Style = .info,
        duration: TimeInterval = 2.0,
        in view: UIView? = nil
    ) {
        // 确保在主线程执行
        DispatchQueue.main.async {
            // 获取要显示 Toast 的视图
            guard let targetView = view ?? UIApplication.shared.keyWindow else { return }
            
            // 配置 Toast
            shared.messageLabel.text = message
            shared.iconImageView.image = UIImage(systemName: style.icon)
            shared.iconImageView.tintColor = style.tintColor
            
            // 添加到目标视图
            targetView.addSubview(shared)
            shared.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            // 设置初始状态
            shared.alpha = 0
            shared.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            
            // 显示动画
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.7,
                options: .curveEaseOut,
                animations: {
                    shared.alpha = 1
                    shared.containerView.transform = .identity
                }
            )
            
            // 取消之前的隐藏计时器
            shared.hideTimer?.invalidate()
            
            // 设置新的隐藏计时器
            shared.hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
                shared.hide()
            }
        }
    }
    
    static func success(_ message: String, duration: TimeInterval = 2.0, in view: UIView? = nil) {
        show(message, style: .success, duration: duration, in: view)
    }
    
    static func failure(_ message: String, duration: TimeInterval = 2.0, in view: UIView? = nil) {
        show(message, style: .failure, duration: duration, in: view)
    }
    
    static func info(_ message: String, duration: TimeInterval = 2.0, in view: UIView? = nil) {
        show(message, style: .info, duration: duration, in: view)
    }
    
    private func hide() {
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.alpha = 0
                self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }
        ) { _ in
            self.removeFromSuperview()
            self.containerView.transform = .identity
        }
    }
} 