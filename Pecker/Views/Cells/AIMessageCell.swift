import UIKit
import SnapKit

class AIMessageCell: UICollectionViewCell {
    // MARK: - Properties
    private let maxBubbleWidth: CGFloat = UIScreen.main.bounds.width * 0.65
    
    // MARK: - UI Elements
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        return imageView
    }()
    
    private let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 18
        view.layer.masksToBounds = true
        return view
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    private let loadingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        view.color = .systemGray
        return view
    }()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(bubbleView)
        contentView.addSubview(timeLabel)
        bubbleView.addSubview(messageLabel)
        bubbleView.addSubview(loadingView)
        
        avatarImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.width.height.equalTo(32)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        }
        
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(bubbleView.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(-8)
            make.height.equalTo(14)
        }
        
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    // MARK: - Configuration
    func configure(with message: AIMessage) {
        messageLabel.isHidden = false
        loadingView.stopAnimating()
        
        messageLabel.text = message.text
        timeLabel.text = formatTime(message.timestamp)
        
        if message.isFromUser {
            setupUserMessage()
        } else {
            setupAIMessage()
        }
        
        updateLayout()
    }
    
    private func setupUserMessage() {
        bubbleView.backgroundColor = .systemPurple.withAlphaComponent(0.1)
        messageLabel.textColor = .systemPurple
        
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = .systemPurple
        
        avatarImageView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.trailing.equalToSuperview().offset(-16)
            make.width.height.equalTo(32)
        }
        
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
    }
    
    private func setupAIMessage() {
        bubbleView.backgroundColor = .secondarySystemBackground
        messageLabel.textColor = .label
        
        avatarImageView.image = UIImage(systemName: "brain.head.profile")
        avatarImageView.tintColor = AppTheme.primary
        
        avatarImageView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(32)
        }
        
        bubbleView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
    }
    
    private func updateLayout() {
        let textWidth = (messageLabel.text ?? "").size(withAttributes: [
            .font: messageLabel.font as Any
        ]).width
        
        let bubbleWidth = min(textWidth + 32, maxBubbleWidth)
        
        bubbleView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.width.equalTo(bubbleWidth)
            
            if messageLabel.textColor == .systemPurple {
                make.trailing.equalTo(avatarImageView.snp.leading).offset(-8)
            } else {
                make.leading.equalTo(avatarImageView.snp.trailing).offset(8)
            }
        }
        
        timeLabel.snp.remakeConstraints { make in
            make.top.equalTo(bubbleView.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(-8)
            make.height.equalTo(14)
            if messageLabel.textColor == .systemPurple {
                make.trailing.equalTo(bubbleView)
            } else {
                make.leading.equalTo(bubbleView)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    func showLoading() {
        messageLabel.isHidden = true
        loadingView.startAnimating()
        
        bubbleView.snp.updateConstraints { make in
            make.width.equalTo(60)
        }
    }
}

// MARK: - Size Calculation
extension AIMessageCell {
    static func size(for message: AIMessage, maxWidth: CGFloat) -> CGSize {
        let maxBubbleWidth = maxWidth * 0.65
        let maxTextWidth = maxBubbleWidth - 32
        
        let textRect = message.text.boundingRect(
            with: CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: UIFont.systemFont(ofSize: 16)],
            context: nil
        )
        
        let bubbleHeight = ceil(textRect.height) + 24
        let totalHeight = bubbleHeight + 26 + 8
        
        return CGSize(width: maxWidth, height: max(totalHeight, 60))
    }
} 
