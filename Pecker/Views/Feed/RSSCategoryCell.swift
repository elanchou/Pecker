import UIKit
import SnapKit

class RSSCategoryCell: UICollectionViewCell {
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
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
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(countLabel)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        iconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(16)
            make.width.height.equalTo(32)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        
        countLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        
        // Add shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.1
        layer.masksToBounds = false
    }
    
    // MARK: - Configuration
    func configure(with category: RSSDirectoryService.RSSCategory) {
        titleLabel.text = category.name
        countLabel.text = "\(category.platforms.count) " + LocalizedString("rss.platforms")
        
        // 设置图标
        switch category.type {
        case .social:
            iconView.image = UIImage(systemName: "person.2.fill")
        case .news:
            iconView.image = UIImage(systemName: "newspaper.fill")
        case .tech:
            iconView.image = UIImage(systemName: "laptopcomputer")
        case .finance:
            iconView.image = UIImage(systemName: "chart.line.uptrend.xyaxis")
        case .entertainment:
            iconView.image = UIImage(systemName: "play.fill")
        case .life:
            iconView.image = UIImage(systemName: "heart.fill")
        case .reading:
            iconView.image = UIImage(systemName: "book.fill")
        case .other:
            iconView.image = UIImage(systemName: "ellipsis.circle.fill")
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.2 : 0.1
    }
} 