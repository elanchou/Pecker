import UIKit
import RealmSwift
import SDWebImage
import SnapKit

class FeedCell: UITableViewCell {
    // MARK: - UI Elements
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()
    
    private let faviconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()
    
    private let urlLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let unreadCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = .systemBlue
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
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
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(unreadCountLabel)
        
        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.equalTo(unreadCountLabel.snp.left).offset(-12)
        }
        
        unreadCountLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(30)
        }
    }
    
    // MARK: - Configuration
    func configure(with feed: Feed) {
        titleLabel.text = feed.title
        urlLabel.text = feed.url
        
        if let url = URL(string: feed.url) {
            let faviconURL = "https://www.google.com/s2/favicons?sz=64&domain=\(url.host ?? "")"
            iconImageView.sd_setImage(
                with: URL(string: faviconURL),
                placeholderImage: UIImage(systemName: "globe"),
                options: [.retryFailed, .progressiveLoad]
            )
        }
        
        if feed.unreadCount > 0 {
            unreadCountLabel.isHidden = false
            unreadCountLabel.text = "\(feed.unreadCount)"
            let width = unreadCountLabel.intrinsicContentSize.width + 16
            unreadCountLabel.widthAnchor.constraint(equalToConstant: max(width, 20)).isActive = true
        } else {
            unreadCountLabel.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.sd_cancelCurrentImageLoad()
        iconImageView.image = UIImage(systemName: "newspaper")
        unreadCountLabel.isHidden = true
    }
} 
