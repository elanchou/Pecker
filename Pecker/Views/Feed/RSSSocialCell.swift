import UIKit
import SnapKit
import Kingfisher

class RSSSocialCell: UICollectionViewCell {
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        return imageView
    }()
    
    private let platformIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .label
        label.numberOfLines = 3
        return label
    }()
    
    private let mediaImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.isHidden = true
        return imageView
    }()
    
    private let statsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(avatarImageView)
        containerView.addSubview(platformIcon)
        containerView.addSubview(nameLabel)
        containerView.addSubview(usernameLabel)
        containerView.addSubview(contentLabel)
        containerView.addSubview(mediaImageView)
        containerView.addSubview(statsLabel)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(12)
            make.width.height.equalTo(40)
        }
        
        platformIcon.snp.makeConstraints { make in
            make.bottom.trailing.equalTo(avatarImageView)
            make.width.height.equalTo(16)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        
        usernameLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.leading.trailing.equalTo(nameLabel)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(usernameLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        
        mediaImageView.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(120)
        }
        
        statsLabel.snp.makeConstraints { make in
            make.top.equalTo(mediaImageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
        
        // Add shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.1
        layer.masksToBounds = false
    }
    
    // MARK: - Configuration
    func configure(with social: RSSSocial) {
        nameLabel.text = social.name
        usernameLabel.text = social.username
        contentLabel.text = social.content
        statsLabel.text = social.stats
        
        // 设置平台图标
        switch social.platform {
        case .weibo:
            platformIcon.image = UIImage(systemName: "message.fill")
        case .twitter:
            platformIcon.image = UIImage(systemName: "bird.fill")
        case .instagram:
            platformIcon.image = UIImage(systemName: "camera.fill")
        }
        
        // 设置头像
        if let url = URL(string: social.avatarURL) {
            avatarImageView.kf.setImage(
                with: url,
                options: [
                    .transition(.fade(0.3)),
                    .processor(DownsamplingImageProcessor(size: CGSize(width: 40, height: 40))),
                    .scaleFactor(UIScreen.main.scale),
                    .cacheOriginalImage
                ]
            )
        }
        
        // 设置媒体图片
        if let mediaURL = social.mediaURL, let url = URL(string: mediaURL) {
            mediaImageView.isHidden = false
            mediaImageView.kf.setImage(
                with: url,
                options: [
                    .transition(.fade(0.3)),
                    .processor(DownsamplingImageProcessor(size: CGSize(width: bounds.width - 24, height: 120))),
                    .scaleFactor(UIScreen.main.scale),
                    .cacheOriginalImage
                ]
            )
        } else {
            mediaImageView.isHidden = true
            // 调整内容标签的约束
            contentLabel.snp.remakeConstraints { make in
                make.top.equalTo(usernameLabel.snp.bottom).offset(8)
                make.leading.trailing.equalToSuperview().inset(12)
                make.bottom.equalTo(statsLabel.snp.top).offset(-8)
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.kf.cancelDownloadTask()
        mediaImageView.kf.cancelDownloadTask()
        avatarImageView.image = nil
        mediaImageView.image = nil
        mediaImageView.isHidden = true
    }
}

// MARK: - RSSSocial Model
struct RSSSocial {
    let id: String
    let platform: SocialPlatform
    let name: String
    let username: String
    let content: String
    let avatarURL: String
    let mediaURL: String?
    let stats: String
    
    enum SocialPlatform {
        case weibo
        case twitter
        case instagram
    }
} 